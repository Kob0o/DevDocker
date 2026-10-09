package org.example.logs;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/v1/logs")
public class LogController {

    private final LogService logs;

    public LogController(LogService logs) {
        this.logs = logs;
    }

    @GetMapping
    public List<LogEntry> list() {
        return logs.all();
    }

    @PostMapping
    public LogEntry create(@RequestBody LogEntry entry) throws IOException {
        return logs.add(entry);
    }
}
