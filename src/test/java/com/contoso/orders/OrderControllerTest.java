package com.contoso.orders;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class OrderControllerTest {

    private static final String NEW_ORDER = """
            {"customerName":"Acme Ltd","product":"Widget","quantity":3,"unitPrice":9.99}
            """;

    @Autowired
    private MockMvc mvc;

    @Test
    void healthIsUp() throws Exception {
        mvc.perform(get("/orders/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void createReturns201WithNewStatusAndTotal() throws Exception {
        mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON).content(NEW_ORDER))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.status").value("NEW"))
                .andExpect(jsonPath("$.total").value(29.97));
    }

    @Test
    void createdOrderCanBeFetchedAndListed() throws Exception {
        MvcResult created = mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON).content(NEW_ORDER))
                .andReturn();
        String id = created.getResponse().getContentAsString().replaceAll(".*\"id\":(\\d+).*", "$1");

        mvc.perform(get("/orders/" + id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.customerName").value("Acme Ltd"));

        mvc.perform(get("/orders"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(org.hamcrest.Matchers.greaterThanOrEqualTo(1))));
    }

    @Test
    void shipMovesOrderToShipped() throws Exception {
        MvcResult created = mvc.perform(post("/orders").contentType(MediaType.APPLICATION_JSON).content(NEW_ORDER))
                .andReturn();
        String id = created.getResponse().getContentAsString().replaceAll(".*\"id\":(\\d+).*", "$1");

        mvc.perform(post("/orders/" + id + "/ship"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SHIPPED"));
    }

    @Test
    void unknownOrderReturns404() throws Exception {
        mvc.perform(get("/orders/999999")).andExpect(status().isNotFound());
        mvc.perform(post("/orders/999999/ship")).andExpect(status().isNotFound());
    }
}
