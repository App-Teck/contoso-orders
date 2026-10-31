package com.contoso.orders;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * API test: boots the real Spring context with the in-memory H2 database and
 * calls the endpoints over MockMvc (no real network port needed).
 * This is what the pipeline will run on every pull request.
 */
@SpringBootTest
@AutoConfigureMockMvc
class OrderControllerTest {

    @Autowired
    private MockMvc mvc;

    @Test
    void healthReportsUp() throws Exception {
        mvc.perform(get("/orders/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void createThenFetchOrder() throws Exception {
        String body = """
                {"customerName":"Alice","product":"Widget","quantity":3,"unitPrice":9.99}
                """;

        String location = mvc.perform(post("/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.status").value("NEW"))
                .andExpect(jsonPath("$.total").value(29.97))
                .andReturn().getResponse().getContentAsString();

        long id = Long.parseLong(location.replaceAll(".*\"id\":(\\d+).*", "$1"));

        mvc.perform(get("/orders/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.customerName").value("Alice"));
    }

    @Test
    void shipChangesStatusToShipped() throws Exception {
        String body = """
                {"customerName":"Bob","product":"Gadget","quantity":1,"unitPrice":5.00}
                """;
        String created = mvc.perform(post("/orders")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        long id = Long.parseLong(created.replaceAll(".*\"id\":(\\d+).*", "$1"));

        mvc.perform(post("/orders/" + id + "/ship"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SHIPPED"));
    }

    @Test
    void unknownOrderReturns404() throws Exception {
        mvc.perform(get("/orders/999999"))
                .andExpect(status().isNotFound());

        mvc.perform(post("/orders/999999/ship"))
                .andExpect(status().isNotFound());
    }

    @Test
    void listReturnsAllOrders() throws Exception {
        mvc.perform(get("/orders"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }
}
