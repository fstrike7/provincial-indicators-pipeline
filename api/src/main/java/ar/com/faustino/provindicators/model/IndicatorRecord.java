package ar.com.faustino.provindicators.model;

import java.time.LocalDate;

public record IndicatorRecord(
        String scopeType,          // alcance_tipo
        String scopeName,          // alcance_nombre
        String activityName,       // actividad_producto_nombre
        String indicatorName,      // indicador
        String unit,               // unidad_de_medida
        String frequency,          // frecuencia_nombre
        LocalDate date,            // indice_tiempo
        Double value,              // valor
        String source              // fuente
) {}
