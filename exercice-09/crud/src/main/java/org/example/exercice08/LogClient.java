package org.example.exercice08;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.Map;

@Component
public class LogClient {

    private final RestTemplate restTemplate;
    private final String logsApiUrl;

    public LogClient(RestTemplate restTemplate, @Value("${logs.api.url}") String logsApiUrl) {
        this.restTemplate = restTemplate;
        this.logsApiUrl = logsApiUrl;
    }

    public void send(String level, String message, String method, String path) {
        Map<String, String> log = Map.of(
                "message", message,
                "source", "[CrudAPI] " + method + " " + path,
                "timestamp", Instant.now().toString(),
                "level", level
        );
        try {
            restTemplate.postForEntity(logsApiUrl + "/api/v1/logs", log, Void.class);
        } catch (Exception ignored) {
        }
    }
}
