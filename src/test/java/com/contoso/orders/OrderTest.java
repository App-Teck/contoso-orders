package com.contoso.orders;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class OrderTest {

    @Test
    void totalIsQuantityTimesUnitPrice() {
        Order order = new Order("Acme Ltd", "Widget", 3, new BigDecimal("9.99"));
        assertThat(order.getTotal()).isEqualByComparingTo("29.97");
    }

    @Test
    void newOrderStartsInNewStatus() {
        Order order = new Order("Acme Ltd", "Widget", 1, BigDecimal.ONE);
        assertThat(order.getStatus()).isEqualTo("NEW");
        assertThat(order.getCreatedAt()).isNotNull();
    }
}
