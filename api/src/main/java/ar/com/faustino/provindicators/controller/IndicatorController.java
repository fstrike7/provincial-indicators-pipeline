package ar.com.faustino.provindicators.controller;

import ar.com.faustino.provindicators.model.IndicatorRecord;
import ar.com.faustino.provindicators.service.IndicatorQueryService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class IndicatorController {

    private final IndicatorQueryService service;

    public IndicatorController(IndicatorQueryService service) {
        this.service = service;
    }

    @GetMapping("/indicators")
    public List<IndicatorRecord> getAll() {
        // TODO: Pagination
        return service.recordsForProvince("Argentina");
    }

    @GetMapping("/provinces")
    public List<String> getProvinces() {
        return service.listProvinces();
    }

    @GetMapping("/provinces/{name}/records")
    public List<IndicatorRecord> getProvinceRecords(@PathVariable String name) {
        return service.recordsForProvince(name);
    }

    @GetMapping("/provinces/{name}/latest")
    public Map<String, Double> getProvinceLatest(@PathVariable String name) {
        return service.latestValuesByIndicator(name);
    }
}
