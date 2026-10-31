package com.contoso.orders;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Pure unit test: no Spring, no database. Runs in milliseconds.
 * Tests the one piece of business logic the app has: the order total.
 */
class OrderTest {

    @Test
    void totalIsQuantityTimesUnitPrice() {
        Order order = new Order("Alice", "Widget", 3, new BigDecimal("9.99"));

        assertThat(order.getTotal()).isEqualByComparingTo("29.97");
    }

    @Test
    void newOrderStartsWithStatusNew() {
        Order order = new Order("Alice", "Widget", 1, BigDecimal.TEN);

        assertThat(order.getStatus()).isEqualTo("NEW");
        assertThat(order.getCreatedAt()).isNotNull();
    }
}
