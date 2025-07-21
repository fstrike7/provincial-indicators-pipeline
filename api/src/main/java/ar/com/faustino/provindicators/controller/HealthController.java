package ar.com.faustino.provindicators.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.ListBucketsResponse;

@RestController
public class HealthController {
    private final S3Client s3Client;

    public HealthController(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    @GetMapping("/health/s3")
    public String checkS3() {
        ListBucketsResponse response = s3Client.listBuckets();
        return "Buckets: " + response.buckets().toString();
    }
}
