package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"
	"crypto/tls"

	"database/sql"
	"fmt"

	_ "github.com/lib/pq"

	kingpin "github.com/alecthomas/kingpin/v2"

	"github.com/IBM/sarama"
)

var (
	brokerList        = kingpin.Flag("brokerList", "List of brokers to connect").Strings()
	topic             = kingpin.Flag("topic", "Topic name").Default("votes").String()
	messageCountStart = kingpin.Flag("messageCountStart", "Message counter start from:").Int()
)

const (
	host     = "postgresql"
	port     = 5432
	user     = "okteto"
	password = "okteto"
	dbname   = "votes"
)

// healthCheckHandler responde a las solicitudes de health check de Cloud Run
func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// startHTTPServer inicia un servidor HTTP en el puerto especificado
func startHTTPServer(port string) {
	http.HandleFunc("/health", healthCheckHandler)
	http.HandleFunc("/", healthCheckHandler)

	log.Printf("HTTP server listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Printf("HTTP server error: %v", err)
	}
}

func main() {
	// Parsear flags primero, antes de leer variables de entorno
	kingpin.Parse()

	// Obtener el puerto de la variable de entorno PORT (Cloud Run la inyecta)
	httpPort := os.Getenv("PORT")
	if httpPort == "" {
		httpPort = "8080"
	}

	// Iniciar el servidor HTTP en una goroutine
	go startHTTPServer(httpPort)

	// Obtener configuración de Kafka desde variables de entorno
	kafkaBroker := os.Getenv("KAFKA_BROKER")
	if kafkaBroker == "" {
		log.Fatal("KAFKA_BROKER environment variable is required")
	}
	*brokerList = []string{kafkaBroker}

	if kafkaTopic := os.Getenv("KAFKA_TOPIC"); kafkaTopic != "" {
		*topic = kafkaTopic
	}

	log.Printf("Starting worker with KAFKA_BROKER=%s, KAFKA_TOPIC=%s", kafkaBroker, *topic)

	db := openDatabase()
	defer db.Close()

	pingDatabase(db)

	dropTableStmt := `DROP TABLE IF EXISTS votes`
	if _, err := db.Exec(dropTableStmt); err != nil {
		log.Printf("Error dropping table: %v", err)
	}

	createTableStmt := `CREATE TABLE IF NOT EXISTS votes (id VARCHAR(255) NOT NULL UNIQUE, vote VARCHAR(255) NOT NULL)`
	if _, err := db.Exec(createTableStmt); err != nil {
		log.Printf("Error creating table: %v", err)
	}

	master := getKafkaMaster()
	defer master.Close()

	// Obtener todas las particiones del topic
	partitions, err := master.Partitions(*topic)
	if err != nil {
		log.Printf("Error getting partitions for topic '%s': %v", *topic, err)
		return
	}
	log.Printf("Topic '%s' has %d partition(s): %v", *topic, len(partitions), partitions)

	signals := make(chan os.Signal, 1)
	signal.Notify(signals, os.Interrupt)
	doneCh := make(chan struct{})

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	messages := make(chan *sarama.ConsumerMessage, 256)
	errors := make(chan *sarama.ConsumerError, 256)

	// Lanzar un goroutine consumer por cada partición
	for _, partition := range partitions {
		pc, err := master.ConsumePartition(*topic, partition, sarama.OffsetOldest)
		if err != nil {
			log.Printf("Error creating consumer for partition %d: %v", partition, err)
			continue
		}
		log.Printf("Consumer created for topic '%s', partition %d", *topic, partition)

		go func(pc sarama.PartitionConsumer) {
			defer pc.Close()
			for {
				select {
				case <-ctx.Done():
					return
				case msg := <-pc.Messages():
					messages <- msg
				case err := <-pc.Errors():
					errors <- err
				}
			}
		}(pc)
	}

	go func() {
		for {
			select {
			case <-ctx.Done():
				log.Println("Context cancelled, exiting consumer loop")
				return
			case err := <-errors:
				fmt.Printf("Consumer error: %v\n", err)
			case msg := <-messages:
				*messageCountStart++
				log.Printf("Received message: user %s vote %s (offset=%d, partition=%d)", string(msg.Key), string(msg.Value), msg.Offset, msg.Partition)

				insertDynStmt := `insert into "votes"("id", "vote") values($1, $2) on conflict(id) do update set vote = $2`
				if _, err := db.Exec(insertDynStmt, *messageCountStart, string(msg.Value)); err != nil {
					log.Printf("Error inserting vote: %v", err)
				} else {
					log.Printf("Vote inserted successfully: id=%d, vote=%s", *messageCountStart, string(msg.Value))
				}
			case <-signals:
				log.Println("Interrupt signal detected, shutting down")
				cancel()
				doneCh <- struct{}{}
				return
			}
		}
	}()

	log.Println("Worker started successfully")
	<-doneCh
	log.Println("Processed", *messageCountStart, "messages")
}

func openDatabase() *sql.DB {
	dbHost := os.Getenv("DATABASE_HOST")
	dbPort := os.Getenv("DATABASE_PORT")
	dbUser := os.Getenv("DATABASE_USER")
	dbPassword := os.Getenv("DATABASE_PASSWORD")
	dbName := os.Getenv("DATABASE_NAME")

	if dbHost == "" {
		dbHost = host
	}
	if dbPort == "" {
		dbPort = fmt.Sprintf("%d", port)
	}
	if dbUser == "" {
		dbUser = user
	}
	if dbPassword == "" {
		dbPassword = password
	}
	if dbName == "" {
		dbName = dbname
	}

	psqlconn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", dbHost, dbPort, dbUser, dbPassword, dbName)

	log.Printf("Connecting to PostgreSQL at %s:%s...", dbHost, dbPort)

	for {
		db, err := sql.Open("postgres", psqlconn)
		if err == nil {
			log.Println("PostgreSQL connection established")
			return db
		}
		log.Printf("Failed to connect to PostgreSQL: %v, retrying in 2s", err)
		time.Sleep(2 * time.Second)
	}
}

func pingDatabase(db *sql.DB) {
	fmt.Println("Waiting for postgresql...")
	for {
		if err := db.Ping(); err == nil {
			fmt.Println("Postgresql connected!")
			return
		}
		time.Sleep(2 * time.Second)
	}
}

type CBState int

const (
	CBClosed   CBState = iota
	CBOpen                    
	CBHalfOpen                
)

type CircuitBreaker struct {
	state        CBState
	failures     int
	maxFailures  int
	openUntil    time.Time
	cooldown     time.Duration
}

func NewCircuitBreaker(maxFailures int, cooldown time.Duration) *CircuitBreaker {
	return &CircuitBreaker{
		state:       CBClosed,
		maxFailures: maxFailures,
		cooldown:    cooldown,
	}
}

func (cb *CircuitBreaker) Allow() bool {
	switch cb.state {
	case CBClosed:
		return true
	case CBOpen:
		if time.Now().After(cb.openUntil) {
			cb.state = CBHalfOpen
			log.Println("Circuit Breaker: transitioning to HALF-OPEN, allowing probe attempt")
			return true
		}
		log.Printf("Circuit Breaker: OPEN, waiting until %s", cb.openUntil.Format(time.RFC3339))
		return false
	case CBHalfOpen:
		return true
	}
	return false
}

func (cb *CircuitBreaker) RecordSuccess() {
	cb.failures = 0
	cb.state = CBClosed
	log.Println("Circuit Breaker: CLOSED (success recorded)")
}

func (cb *CircuitBreaker) RecordFailure() {
	cb.failures++
	if cb.state == CBHalfOpen || cb.failures >= cb.maxFailures {
		cb.state = CBOpen
		cb.openUntil = time.Now().Add(cb.cooldown)
		log.Printf("Circuit Breaker: OPEN after %d failures, cooling down for %s", cb.failures, cb.cooldown)
	}
}

func getKafkaMaster() sarama.Consumer {
    config := sarama.NewConfig()
    config.Consumer.Return.Errors = true
    config.Consumer.Offsets.Initial = sarama.OffsetOldest
    config.Consumer.Group.Rebalance.Strategy = sarama.BalanceStrategyRoundRobin
    config.Consumer.Group.Session.Timeout = 10 * time.Second

    // Soporte para SASL (Confluent Cloud)
    if apiKey := os.Getenv("KAFKA_API_KEY"); apiKey != "" {
        config.Net.SASL.Enable = true
        config.Net.SASL.User = apiKey
        config.Net.SASL.Password = os.Getenv("KAFKA_API_SECRET")
        config.Net.SASL.Mechanism = sarama.SASLTypePlaintext
        config.Net.TLS.Enable = true
        config.Net.TLS.Config = &tls.Config{
            InsecureSkipVerify: false,
        }
        log.Println("SASL authentication configured for Confluent Cloud")
    }

    brokers := *brokerList
    log.Printf("Connecting to Kafka brokers: %v", brokers)

    // Circuit Breaker: abre tras 5 fallos consecutivos, espera 30s antes de reintentar
    cb := NewCircuitBreaker(5, 30*time.Second)

    for {
        if !cb.Allow() {
            // Circuito abierto: esperar sin bombardear Kafka
            time.Sleep(5 * time.Second)
            continue
        }

        master, err := sarama.NewConsumer(brokers, config)
        if err == nil {
            cb.RecordSuccess()
            log.Println("Kafka connected successfully!")
            return master
        }

        cb.RecordFailure()
        log.Printf("Failed to connect to Kafka: %v, retrying in 2s", err)
        time.Sleep(2 * time.Second)
    }
}