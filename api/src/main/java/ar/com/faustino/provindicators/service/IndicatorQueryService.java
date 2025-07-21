package ar.com.faustino.provindicators.service;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import ar.com.faustino.provindicators.model.IndicatorRecord;

@Service
public class IndicatorQueryService {
    private final IndicatorDataLoader loader;

    public IndicatorQueryService(IndicatorDataLoader loader) {
        this.loader = loader;
    }

    public List<String> listProvinces() {
        return loader.loadAll().stream()
                .filter(r -> "PROVINCIA".equalsIgnoreCase(r.scopeType()))
                .map(IndicatorRecord::scopeName)
                .distinct()
                .sorted()
                .toList();
    }

    public List<IndicatorRecord> recordsForProvince(String province) {
        return loader.loadAll().stream()
                .filter(r -> "PROVINCIA".equalsIgnoreCase(r.scopeType()))
                .filter(r -> r.scopeName().equalsIgnoreCase(province))
                .toList();
    }

    public Map<String, Double> latestValuesByIndicator(String province) {
        return loader.loadAll().stream()
                .filter(r -> "PROVINCIA".equalsIgnoreCase(r.scopeType()))
                .filter(r -> r.scopeName().equalsIgnoreCase(province))
                .collect(Collectors.groupingBy(
                        IndicatorRecord::indicatorName,
                        Collectors.collectingAndThen(
                                Collectors.maxBy(Comparator.comparing(IndicatorRecord::date)),
                                opt -> opt.map(IndicatorRecord::value).orElse(null)
                        )
                ));
    }
}
