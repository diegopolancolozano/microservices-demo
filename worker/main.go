package main

import (
	"context"
	"crypto/tls"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/IBM/sarama"
	kingpin "github.com/alecthomas/kingpin/v2"
	_ "github.com/lib/pq"
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

func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func startHTTPServer(port string) {
	http.HandleFunc("/health", healthCheckHandler)
	http.HandleFunc("/", healthCheckHandler)
	log.Printf("HTTP server listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Printf("HTTP server error: %v", err)
	}
}

func main() {
	kingpin.Parse()

	httpPort := os.Getenv("PORT")
	if httpPort == "" {
		httpPort = "8080"
	}
	go startHTTPServer(httpPort)

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

	// ELIMINADO: DROP TABLE - ya no se borran los votos en cada inicio
	// Solo crear la tabla si no existe
	createTableStmt := `CREATE TABLE IF NOT EXISTS votes (id VARCHAR(255) NOT NULL UNIQUE, vote VARCHAR(255) NOT NULL)`
	if _, err := db.Exec(createTableStmt); err != nil {
		log.Printf("Error creating table: %v", err)
	} else {
		log.Println("Table 'votes' ready")
	}

	master := getKafkaMaster()
	defer master.Close()

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
	errorsChan := make(chan *sarama.ConsumerError, 256)

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
					errorsChan <- err
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
			case err := <-errorsChan:
				log.Printf("Consumer error: %v", err)
			case msg := <-messages:
				*messageCountStart++
				log.Printf("Received message: user %s vote %s (offset=%d, partition=%d)", string(msg.Key), string(msg.Value), msg.Offset, msg.Partition)

				// Usar msg.Key (UUID del usuario) como ID, no el contador
				insertDynStmt := `insert into "votes"("id", "vote") values($1, $2) on conflict(id) do update set vote = $2`
				if _, err := db.Exec(insertDynStmt, string(msg.Key), string(msg.Value)); err != nil {
					log.Printf("Error inserting vote: %v", err)
				} else {
					log.Printf("Vote inserted successfully: id=%s, vote=%s", string(msg.Key), string(msg.Value))
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
    log.Println("Pinging PostgreSQL...")
    for {
        err := db.Ping()
        if err == nil {
            log.Println("Postgresql ping successful!")
            return
        }
        log.Printf("Postgresql ping failed: %v, retrying in 2s", err)
        time.Sleep(2 * time.Second)
    }
}

func getKafkaMaster() sarama.Consumer {
	config := sarama.NewConfig()
	config.Consumer.Return.Errors = true
	config.Consumer.Offsets.Initial = sarama.OffsetOldest
	config.Consumer.Group.Rebalance.Strategy = sarama.BalanceStrategyRoundRobin
	config.Consumer.Group.Session.Timeout = 10 * time.Second

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

	for {
		master, err := sarama.NewConsumer(brokers, config)
		if err == nil {
			log.Println("Kafka connected successfully!")
			return master
		}
		log.Printf("Failed to connect to Kafka: %v, retrying in 2s", err)
		time.Sleep(2 * time.Second)
	}
}