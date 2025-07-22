package ar.com.faustino.provindicators.service;

import ar.com.faustino.provindicators.model.IndicatorRecord;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Bean;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class IndicatorQueryServiceTest {

    @TestConfiguration
    static class StubConfig {
        @Bean
        IndicatorDataLoader indicatorDataLoader() {
            return new IndicatorDataLoaderStub();
        }
    }

    static class IndicatorDataLoaderStub extends IndicatorDataLoader {
        IndicatorDataLoaderStub() {
            super(null, "unused");
        }

        @Override
        public List<IndicatorRecord> loadAll() {
            return List.of(
                    new IndicatorRecord("PROVINCIA", "BUENOS AIRES", "Actividad X", "Indicador A", "unidad", "Anual", LocalDate.of(2023,1,1), 10.0, "Fuente"),
                    new IndicatorRecord("PROVINCIA", "CORDOBA", "Actividad Y", "Indicador B", "unidad", "Anual", LocalDate.of(2023,1,1), 20.0, "Fuente"),
                    new IndicatorRecord("PAIS", "Argentina", "Actividad Z", "Indicador C", "unidad", "Anual", LocalDate.of(2023,1,1), 30.0, "Fuente")
            );
        }
    }

    @Autowired
    private IndicatorQueryService service;

    @Test
    void listProvincesShouldFilterOnlyProvincia() {
        List<String> provinces = service.listProvinces();
        assertTrue(provinces.contains("BUENOS AIRES"));
        assertTrue(provinces.contains("CORDOBA"));
        assertFalse(provinces.contains("Argentina"));
        assertEquals(2, provinces.size());
    }
}
