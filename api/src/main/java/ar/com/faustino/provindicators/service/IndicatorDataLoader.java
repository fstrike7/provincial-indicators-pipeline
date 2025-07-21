package ar.com.faustino.provindicators.service;

import ar.com.faustino.provindicators.model.IndicatorRecord;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@Service
public class IndicatorDataLoader {

    private final S3Client s3Client;
    private final String bucket;
    private static final String RAW_KEY = "raw/indicadores-provinciales.csv";

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    public IndicatorDataLoader(
            S3Client s3Client,
            @Value("${aws.s3.bucket}") String bucket
    ) {
        this.s3Client = s3Client;
        this.bucket = bucket;
    }

    public List<IndicatorRecord> loadAll() {
        var req = GetObjectRequest.builder()
                .bucket(bucket)
                .key(RAW_KEY)
                .build();

        var records = new ArrayList<IndicatorRecord>();

        try (var s3Stream = s3Client.getObject(req);
             var reader = new BufferedReader(new InputStreamReader(s3Stream, Charset.forName("ISO-8859-1")))) {

            CSVFormat format = CSVFormat.DEFAULT.builder()
                    .setHeader()              // auto-detecta headers de la primera fila
                    .setSkipHeaderRecord(true)
                    .setIgnoreHeaderCase(true)
                    .setTrim(true)
                    .build();

            try (CSVParser parser = new CSVParser(reader, format)) {
                for (CSVRecord r : parser) {
                    String scopeType = r.get("alcance_tipo").trim();
                    String scopeName = r.get("alcance_nombre").trim();
                    String activity = r.get("actividad_producto_nombre").trim();
                    String indicator = r.get("indicador").trim();
                    String unit = r.get("unidad_de_medida").trim();
                    String freq = r.get("frecuencia_nombre").trim();
                    String dateStr = r.get("indice_tiempo").trim();
                    LocalDate date = LocalDate.parse(dateStr, DATE_FMT);
                    String source = r.get("fuente").trim();

                    Double value = parseDoubleSafe(r.get("valor"));

                    records.add(new IndicatorRecord(
                            scopeType,
                            scopeName,
                            activity,
                            indicator,
                            unit,
                            freq,
                            date,
                            value,
                            source
                    ));
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("Error leyendo CSV desde S3: " + e.getMessage(), e);
        }

        return records;
    }

    private static Double parseDoubleSafe(String raw) {
        if (raw == null) return null;
        String cleaned = raw.trim().replace(",", "."); // case: if decimal
        if (cleaned.isEmpty()) return null;
        try {
            return Double.parseDouble(cleaned);
        } catch (NumberFormatException ex) {
            return null;
        }
    }
}
