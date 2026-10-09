package org.example.exercice08;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class CrudLogFilter extends OncePerRequestFilter {

    private final LogClient logs;

    public CrudLogFilter(LogClient logs) {
        this.logs = logs;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        chain.doFilter(request, response);
        int status = response.getStatus();
        String level = status >= 400 ? "ERR" : "INFO";
        String message = status + " " + HttpStatus.valueOf(status).getReasonPhrase();
        logs.send(level, message, request.getMethod(), request.getRequestURI());
    }
}
