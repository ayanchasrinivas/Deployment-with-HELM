package com.orderflow;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import java.util.Map;

@RestController
public class OrderController {
    private static final Logger log = LoggerFactory.getLogger(OrderController.class);

    private final RestTemplate rest;

    @Value("${pricing.url}")
    private String pricingUrl;

    @Value("${app.version:dev}")
    private String appVersion;

    public OrderController(RestTemplate rest) {
        this.rest = rest;
    }

    @PostMapping("/orders")
    public ResponseEntity<Map<String, Object>> createOrder(@RequestBody Map<String, Object> body) {
        String sku = String.valueOf(body.getOrDefault("sku", "UNKNOWN"));
        int qty = (int) body.getOrDefault("quantity", 1);

        log.info("creating order sku={} qty={}", sku, qty);

        Map<?, ?> price = rest.postForObject(
            pricingUrl + "/price",
            Map.of("sku", sku, "quantity", qty),
            Map.class
        );

        return ResponseEntity.ok(Map.of(
            "orderId", java.util.UUID.randomUUID().toString(),
            "sku", sku,
            "quantity", qty,
            "pricing", price,
            "version", appVersion
        ));
    }

    @GetMapping("/version")
    public Map<String, String> version() {
        return Map.of("service", "order-api", "version", appVersion);
    }
}