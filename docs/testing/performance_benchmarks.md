# Performance Benchmarks

## Overview

This document defines performance benchmarks for Juan Heart Mobile across different device categories. These benchmarks ensure the app provides a good user experience on all target devices, especially low-end devices common in the Philippine market.

**Last Updated**: 2025-01-10
**Version**: 1.0.0+1

## Device Categories

### Low-End Devices
**Target Market**: High priority - Common in rural Philippines
**Specs**: 2GB RAM, older processors (Cortex-A53), Android 5.0-6.0 (API 21-23)
**Examples**: Samsung Galaxy J2, Oppo A3s, Vivo Y11

### Mid-Range Devices
**Target Market**: High priority - Most common in urban areas
**Specs**: 4-6GB RAM, mid-range processors (Snapdragon 6xx), Android 8.0-11.0 (API 26-30)
**Examples**: Xiaomi Redmi Note 10, Samsung Galaxy A52, Realme 8

### High-End Devices
**Target Market**: Medium priority - Premium users
**Specs**: 8GB+ RAM, flagship processors (Snapdragon 8xx), Android 12.0+ (API 31+)
**Examples**: Samsung Galaxy S23, Google Pixel 7, OnePlus 11

## Performance Benchmarks by Category

### 1. App Launch Time

Time from tap to interactive UI.

| Device Category | Cold Start | Warm Start | Hot Start | Measurement |
|----------------|-----------|------------|-----------|-------------|
| **Low-End** | <4s | <2s | <1s | Splash → Home screen |
| **Mid-Range** | <3s | <1.5s | <0.5s | Splash → Home screen |
| **High-End** | <2s | <1s | <0.3s | Splash → Home screen |

**Critical**: Low-end devices must launch within 4 seconds or users will perceive app as slow.

### 2. Memory Usage

RAM consumption during various app states.

| Device Category | Idle | Active (Assessment) | Peak (PDF Gen) | Max Allowed |
|----------------|------|-------------------|---------------|-------------|
| **Low-End** | <80MB | <150MB | <200MB | 250MB |
| **Mid-Range** | <70MB | <120MB | <150MB | 200MB |
| **High-End** | <60MB | <100MB | <120MB | 150MB |

**Critical**: Must not exceed max allowed or risk OOM kills on low-RAM devices.

### 3. Battery Drain

Battery consumption per hour of usage.

| Device Category | Background | Active Use | GPS Active | Max Allowed |
|----------------|-----------|-----------|-----------|-------------|
| **Low-End** | <2%/hr | <10%/hr | <15%/hr | 20%/hr |
| **Mid-Range** | <1.5%/hr | <8%/hr | <12%/hr | 15%/hr |
| **High-End** | <1%/hr | <6%/hr | <10%/hr | 12%/hr |

**Critical**: Excessive battery drain leads to uninstalls, especially on older devices.

### 4. Screen Rendering

Frame rate and UI responsiveness.

| Device Category | Target FPS | Min FPS | Jank Tolerance | Touch Response |
|----------------|-----------|---------|---------------|---------------|
| **Low-End** | 30fps | 24fps | <5% frames | <200ms |
| **Mid-Range** | 60fps | 45fps | <3% frames | <100ms |
| **High-End** | 60fps | 55fps | <1% frames | <50ms |

**Critical**: UI must feel responsive even on low-end devices.

### 5. Network Performance

API response handling on different network conditions.

| Network Type | Timeout | Retry | Expected Response | Offline Fallback |
|-------------|---------|-------|------------------|------------------|
| **2G Edge** | 30s | 3x | Progressive loading | Immediate |
| **3G** | 10s | 3x | Full response | After 3s |
| **4G/WiFi** | 5s | 2x | Full response | After 5s |

**Critical**: Must handle poor connectivity gracefully (common in rural areas).

## Feature-Specific Benchmarks

### Heart Risk Assessment Flow

Complete assessment from start to result display.

| Device Category | Symptom Selection | Vitals Input | Risk Calculation | Total Time | Max Allowed |
|----------------|------------------|--------------|------------------|-----------|-------------|
| **Low-End** | <5s | <5s | <1s | <30s | 45s |
| **Mid-Range** | <3s | <3s | <0.5s | <20s | 30s |
| **High-End** | <2s | <2s | <0.3s | <15s | 20s |

**Critical**: Assessment must complete quickly to not disrupt clinical workflow.

### Offline Sync Queue Processing

Time to process and sync offline data when connection restored.

| Device Category | 1 Item | 10 Items | 50 Items | Max Queue Size |
|----------------|--------|----------|----------|---------------|
| **Low-End** | <3s | <30s | <2min | 100 items |
| **Mid-Range** | <2s | <20s | <1.5min | 200 items |
| **High-End** | <1s | <10s | <1min | 500 items |

**Critical**: Users should not wait long for sync after going online.

### GPS Facility Search

Time to get location and display sorted facility list.

| Device Category | Location Fix | Search & Sort | Display Results | Total Time |
|----------------|-------------|--------------|----------------|-----------|
| **Low-End** | <10s | <3s | <1s | <15s |
| **Mid-Range** | <5s | <2s | <1s | <10s |
| **High-End** | <3s | <1s | <0.5s | <5s |

**Critical**: Emergency feature must work quickly.

### PDF Generation

Time to generate and display referral PDF.

| Device Category | Simple PDF | Complex PDF | With Images | Max Time |
|----------------|-----------|------------|-------------|----------|
| **Low-End** | <3s | <5s | <8s | 10s |
| **Mid-Range** | <2s | <3s | <5s | 7s |
| **High-End** | <1s | <2s | <3s | 5s |

**Critical**: Must not block UI during generation.

### CSV Export

Time to export analytics data to CSV file.

| Device Category | 100 Records | 1000 Records | 5000 Records | Max Time |
|----------------|------------|--------------|--------------|----------|
| **Low-End** | <2s | <5s | <15s | 30s |
| **Mid-Range** | <1s | <3s | <10s | 20s |
| **High-End** | <0.5s | <2s | <5s | 10s |

**Critical**: Large exports should not crash app.

### Appointment Booking Flow

Complete flow from date selection to confirmation.

| Device Category | Date Selection | Form Fill | API Call | Total Time |
|----------------|---------------|----------|----------|-----------|
| **Low-End** | <2s | <5s | <5s | <15s |
| **Mid-Range** | <1s | <3s | <3s | <10s |
| **High-End** | <0.5s | <2s | <2s | <5s |

**Critical**: Should feel instant on good networks.

## Database Performance

### Local Database Operations

Hive/Drift query performance.

| Operation | Low-End | Mid-Range | High-End | Max Allowed |
|-----------|---------|-----------|----------|-------------|
| **Read Single** | <10ms | <5ms | <3ms | 50ms |
| **Read List (100)** | <50ms | <30ms | <20ms | 100ms |
| **Write Single** | <20ms | <10ms | <5ms | 100ms |
| **Write Batch (100)** | <200ms | <100ms | <50ms | 500ms |
| **Query Complex** | <100ms | <50ms | <30ms | 300ms |

**Critical**: Database should not block UI thread.

### Cache Performance

Image and data caching.

| Operation | Low-End | Mid-Range | High-End | Max Allowed |
|-----------|---------|-----------|----------|-------------|
| **Cache Hit** | <10ms | <5ms | <3ms | 20ms |
| **Cache Miss** | <100ms | <50ms | <30ms | 200ms |
| **Cache Write** | <50ms | <30ms | <20ms | 100ms |
| **Cache Clear** | <200ms | <100ms | <50ms | 500ms |

**Critical**: Cache should improve performance, not hinder it.

## UI Performance

### List Scrolling

ListView and GridView performance.

| Device Category | Small List (<50) | Medium List (50-200) | Large List (>200) | FPS Target |
|----------------|-----------------|---------------------|------------------|-----------|
| **Low-End** | 30fps | 24fps | 20fps | >24fps |
| **Mid-Range** | 60fps | 50fps | 40fps | >45fps |
| **High-End** | 60fps | 60fps | 55fps | >55fps |

**Critical**: Use lazy loading and pagination for large lists.

### Animation Performance

Transitions and micro-interactions.

| Device Category | Simple Animation | Complex Animation | Page Transition | Target Duration |
|----------------|-----------------|------------------|----------------|----------------|
| **Low-End** | 200-300ms | 300-400ms | 300ms | <500ms |
| **Mid-Range** | 150-250ms | 200-300ms | 250ms | <400ms |
| **High-End** | 100-200ms | 150-250ms | 200ms | <300ms |

**Critical**: Animations should enhance UX, not slow it down.

### Form Input Responsiveness

Text field and button interaction delay.

| Device Category | Keystroke Echo | Button Feedback | Form Validation | Max Delay |
|----------------|---------------|----------------|----------------|-----------|
| **Low-End** | <100ms | <150ms | <300ms | 500ms |
| **Mid-Range** | <50ms | <100ms | <200ms | 300ms |
| **High-End** | <30ms | <50ms | <100ms | 150ms |

**Critical**: Input lag is highly noticeable and frustrating.

## Network Efficiency

### API Call Performance

Backend API response times.

| Endpoint | 4G/WiFi | 3G | 2G | Timeout |
|----------|---------|----|----|---------|
| **Login** | <1s | <3s | <10s | 30s |
| **Assessment** | <1s | <3s | <10s | 30s |
| **Sync** | <2s | <5s | <15s | 45s |
| **Facilities** | <1s | <3s | <10s | 30s |

**Critical**: Must handle slow networks gracefully.

### Data Transfer Optimization

Network bandwidth usage.

| Operation | Small (<10KB) | Medium (10-100KB) | Large (>100KB) | Compression |
|-----------|--------------|------------------|---------------|-------------|
| **JSON API** | <5KB | <50KB | <100KB | Gzip |
| **Images** | <20KB | <100KB | <500KB | WebP/JPEG |
| **PDF** | <50KB | <500KB | <2MB | Optimized |

**Critical**: Minimize data usage for users on limited data plans.

## Testing Methodology

### How to Measure

1. **App Launch Time**
   ```dart
   final start = DateTime.now();
   // App initialization
   final launchTime = DateTime.now().difference(start);
   ```

2. **Memory Usage**
   - Use Flutter DevTools Memory profiler
   - Monitor during typical user flows
   - Check for memory leaks

3. **Battery Drain**
   - Use platform-specific battery profilers
   - Android: Battery Historian
   - iOS: Instruments Energy Log

4. **Frame Rate**
   - Flutter DevTools Performance tab
   - Look for jank (dropped frames)
   - Profile during scrolling and animations

5. **Network Performance**
   - Use Chrome DevTools Network throttling
   - Test on actual 2G/3G connections
   - Measure API response times

### Performance Testing Tools

1. **Flutter DevTools**
   - Performance overlay
   - Memory profiler
   - Network inspector

2. **Android Studio Profiler**
   - CPU profiler
   - Memory profiler
   - Network profiler

3. **Xcode Instruments**
   - Time Profiler
   - Allocations
   - Network

4. **Firebase Performance Monitoring**
   - Real-time monitoring
   - Custom traces
   - Network request tracking

## Performance Checklist

Before each release, verify:

- [ ] App launch time meets benchmarks
- [ ] Memory usage stays within limits
- [ ] No memory leaks detected
- [ ] Battery drain acceptable
- [ ] UI maintains target frame rate
- [ ] Network calls timeout appropriately
- [ ] Offline mode works smoothly
- [ ] Database queries are optimized
- [ ] Images are properly cached
- [ ] Large lists use lazy loading
- [ ] PDF generation is non-blocking
- [ ] CSV export doesn't crash
- [ ] Animations are smooth
- [ ] Form input is responsive

## Optimization Strategies

### When Performance Falls Below Benchmarks

1. **Slow App Launch**
   - Reduce initialization work
   - Lazy load dependencies
   - Defer non-critical tasks

2. **High Memory Usage**
   - Optimize image sizes
   - Clear caches appropriately
   - Fix memory leaks

3. **Excessive Battery Drain**
   - Reduce background activity
   - Optimize GPS usage
   - Batch network requests

4. **Poor Frame Rate**
   - Simplify widget tree
   - Use const constructors
   - Avoid rebuilds

5. **Slow Network**
   - Implement proper caching
   - Compress data
   - Show loading states

## Continuous Monitoring

### Production Metrics

Monitor in production using Firebase Performance:
- App launch time (P50, P95, P99)
- Screen rendering performance
- Network request latency
- Crash-free rate per device
- ANR (Application Not Responding) rate

### Alert Thresholds

Set alerts when:
- P95 launch time > 150% of benchmark
- Memory usage > 90% of max allowed
- Crash rate > 1%
- ANR rate > 0.5%

---

**Status**: NOT VERIFIED AND TESTED
**Next Update**: After first performance test run
**Maintainer**: JH-QA-Guardian
