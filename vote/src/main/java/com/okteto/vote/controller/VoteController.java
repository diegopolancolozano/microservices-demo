package com.okteto.vote.controller;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.thymeleaf.util.StringUtils;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Controller
public class VoteController {
    private static final String OPTION_A_ENV_VAR = "OPTION_A";
    private static final String OPTION_B_ENV_VAR = "OPTION_B";
    private static final String KAFKA_TOPIC = "topic_0";

    // Rate Limiting: 5 requests por minuto por IP
    private final ConcurrentHashMap<String, AtomicInteger> requestCounts = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Long> resetTimes = new ConcurrentHashMap<>();
    private static final int MAX_REQUESTS = 5;
    private static final long TIME_WINDOW_MS = 60000; // 1 minuto

    private final Logger logger = LoggerFactory.getLogger(VoteController.class);

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @GetMapping("/")
    String index(@CookieValue(name = "voter_id", defaultValue = "") String voterId,
                 Model model,
                 HttpServletResponse response) {
        String voter = voterId;
        Vote v = new Vote();
        model.addAttribute("optionA", v.getOptionA());
        model.addAttribute("optionB", v.getOptionB());
        model.addAttribute("hostname", v.getHostname());
        model.addAttribute("vote", null);

        if (StringUtils.isEmpty(voter)) {
            voter = UUID.randomUUID().toString();
        }

        Cookie cookie = new Cookie("voter_id", voter);
        response.addCookie(cookie);

        return "index";
    }

    @PostMapping("/")
    String postForm(@CookieValue(name = "voter_id", defaultValue = "") String voterId,
                    @ModelAttribute Vote voteInput,
                    Model model,
                    HttpServletResponse response,
                    HttpServletRequest request) {

        // ============================================
        // RATE LIMITING - 5 requests por minuto
        // ============================================
        String clientIp = request.getRemoteAddr();
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isEmpty()) {
            clientIp = xff.split(",")[0];
        }

        long now = System.currentTimeMillis();
        Long resetTime = resetTimes.get(clientIp);

        if (resetTime == null || now > resetTime) {
            // Nuevo minuto, reiniciar contador
            resetTimes.put(clientIp, now + TIME_WINDOW_MS);
            requestCounts.put(clientIp, new AtomicInteger(1));
        } else {
            int count = requestCounts.get(clientIp).incrementAndGet();
            if (count > MAX_REQUESTS) {
                response.setStatus(429);
                response.setContentType("application/json");
                try {
                    response.getWriter().write("{\"error\": \"Rate limit exceeded. Max " + MAX_REQUESTS + " requests per minute.\"}");
                } catch (Exception e) {
                    logger.error("Error writing rate limit response", e);
                }
                return null;
            }
        }
        // ============================================
        // FIN RATE LIMITING
        // ============================================

        String voter = voterId;
        String vote = voteInput.getVote();
        Vote v = new Vote();
        model.addAttribute("optionA", v.getOptionA());
        model.addAttribute("optionB", v.getOptionB());
        model.addAttribute("hostname", v.getHostname());
        // We pass the vote received in the post request
        model.addAttribute("vote", vote);
        if (StringUtils.isEmpty(voter)) {
            voter = UUID.randomUUID().toString();
        }
        logger.info(String.format("vote received for '%s'!", vote));

        Cookie cookie = new Cookie("voter_id", voter);
        response.addCookie(cookie);

        CompletableFuture<SendResult<String, String>> future = kafkaTemplate.send(KAFKA_TOPIC, voter, vote);

        future.whenComplete((result, ex) -> {
            if (ex == null) {
                logger.info("Message [{}] delivered with offset {}",
                        vote,
                        result.getRecordMetadata().offset());
            } else {
                logger.warn("Unable to deliver message [{}]. {}",
                        vote,
                        ex.getMessage());
            }
        });

        return "index";
    }

    public static class Vote {
        private String optionA = "Burritos";
        private String optionB = "Tacos";
        private String hostname = "unknown";
        private String vote;

        public String getOptionA() {
            String result = System.getenv(OPTION_A_ENV_VAR);
            return StringUtils.isEmpty(result) ? this.optionA : result;
        }

        public void setOptionA(String optionA) {
            this.optionA = optionA;
        }

        public String getOptionB() {
            String result = System.getenv(OPTION_B_ENV_VAR);
            return StringUtils.isEmpty(result) ? this.optionB : result;
        }

        public void setOptionB(String optionB) {
            this.optionB = optionB;
        }

        public String getHostname() {
            try {
                return InetAddress.getLocalHost().getHostName();
            } catch (UnknownHostException e) {
                return this.hostname;
            }
        }

        public void setHostname(String hostname) {
            this.hostname = hostname;
        }

        public String getVote() {
            return vote;
        }

        public void setVote(String vote) {
            this.vote = vote;
        }
    }
}
