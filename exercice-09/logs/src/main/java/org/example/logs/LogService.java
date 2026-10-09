package org.example.logs;

import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;

@Service
public class LogService {

    private static final String SEPARATOR = "\u001f";
    private final Path file = Path.of("/app/logs.txt");
    private final List<LogEntry> logs = new ArrayList<>();

    public LogService() throws IOException {
        if (Files.exists(file)) {
            for (String line : Files.readAllLines(file)) {
                if (!line.isBlank()) {
                    logs.add(parse(line));
                }
            }
        }
    }

    public synchronized List<LogEntry> all() {
        return List.copyOf(logs);
    }

    public synchronized LogEntry add(LogEntry entry) throws IOException {
        logs.add(entry);
        Files.writeString(file, format(entry) + System.lineSeparator(),
                StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        return entry;
    }

    private static String format(LogEntry entry) {
        return String.join(SEPARATOR, entry.getMessage(), entry.getSource(), entry.getTimestamp(), entry.getLevel().name());
    }

    private static LogEntry parse(String line) {
        String[] parts = line.split(SEPARATOR, 4);
        LogEntry entry = new LogEntry();
        entry.setMessage(parts[0]);
        entry.setSource(parts[1]);
        entry.setTimestamp(parts[2]);
        entry.setLevel(Level.valueOf(parts[3]));
        return entry;
    }
}
