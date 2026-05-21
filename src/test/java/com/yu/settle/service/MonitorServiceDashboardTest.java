package com.yu.settle.service;

import com.yu.settle.model.DashboardSummary;
import com.yu.settle.model.MonitorSnapshot;
import com.yu.settle.util.SettleConstant;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.*;

class MonitorServiceDashboardTest {

    private MonitorService monitorService = new MonitorService();

    @Test
    @DisplayName("all normal channels -> HEALTHY, healthPct=100")
    void allNormalChannels() {
        MonitorSnapshot s1 = buildSnapshot("MTTO", SettleConstant.CHECK_STATUS_NORMAL, 1000, 1000);
        MonitorSnapshot s2 = buildSnapshot("ELM", SettleConstant.CHECK_STATUS_NORMAL, 2000, 2000);
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Arrays.asList(s1, s2));
        assertEquals(2, summary.getTotalCount());
        assertEquals(2, summary.getNormalCount());
        assertEquals(0, summary.getWaitingCount());
        assertEquals("HEALTHY", summary.getOverallStatus());
        assertEquals(100, summary.getHealthPct());
    }

    @Test
    @DisplayName("one MISSING -> WARNING, healthPct=50")
    void oneMissingCausesWarning() {
        MonitorSnapshot s1 = buildSnapshot("MTTO", SettleConstant.CHECK_STATUS_NORMAL, 1000, 1000);
        MonitorSnapshot s2 = buildSnapshot("ELM", SettleConstant.CHECK_STATUS_MISSING, null, null);
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Arrays.asList(s1, s2));
        assertEquals("WARNING", summary.getOverallStatus());
        assertEquals(50, summary.getHealthPct());
        assertEquals(1, summary.getMissingCount());
    }

    @Test
    @DisplayName("empty channel list -> healthPct=0, totalCount=0, HEALTHY")
    void emptyChannelList() {
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Collections.emptyList());
        assertEquals(0, summary.getTotalCount());
        assertEquals(0, summary.getHealthPct());
        assertEquals("HEALTHY", summary.getOverallStatus());
    }

    @Test
    @DisplayName("WAITING and IN_PROGRESS count as healthy (waiting category)")
    void waitingCountsAsHealthy() {
        MonitorSnapshot s1 = buildSnapshot("MTTO", SettleConstant.CHECK_STATUS_WAITING, null, null);
        MonitorSnapshot s2 = buildSnapshot("ELM", SettleConstant.CHECK_STATUS_IN_PROGRESS, 1500, 1500);
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Arrays.asList(s1, s2));
        assertEquals(2, summary.getWaitingCount());
        assertEquals(100, summary.getHealthPct());
    }

    @Test
    @DisplayName("global amount aggregation: totalCiticAmount and totalCheckoutAmount summed correctly")
    void globalAmountAggregation() {
        MonitorSnapshot s1 = buildSnapshot("MTTO", SettleConstant.CHECK_STATUS_NORMAL,
                new BigDecimal("1000"), new BigDecimal("900"));
        MonitorSnapshot s2 = buildSnapshot("ELM", SettleConstant.CHECK_STATUS_NORMAL,
                new BigDecimal("2000"), new BigDecimal("1900"));
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Arrays.asList(s1, s2));
        assertEquals(new BigDecimal("3000"), summary.getTotalCiticAmount());
        assertEquals(new BigDecimal("2800"), summary.getTotalCheckoutAmount());
    }

    @Test
    @DisplayName("avgYoyChange excludes nulls; avgWowChange null when no data")
    void avgChangeExcludesNulls() {
        MonitorSnapshot s1 = buildSnapshot("MTTO", SettleConstant.CHECK_STATUS_NORMAL, 1000, 1000);
        s1.setSnapshotAmountYoyChange(new BigDecimal("0.10"));
        MonitorSnapshot s2 = buildSnapshot("ELM", SettleConstant.CHECK_STATUS_NORMAL, 2000, 2000);
        s2.setSnapshotAmountYoyChange(new BigDecimal("0.20"));
        MonitorSnapshot s3 = buildSnapshot("DYGP", SettleConstant.CHECK_STATUS_MISSING, null, null);
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Arrays.asList(s1, s2, s3));
        assertEquals(new BigDecimal("0.1500"), summary.getAvgYoyChange());
        assertNull(summary.getAvgWowChange());
    }

    // --- helpers ---

    private MonitorSnapshot buildSnapshot(String channel, String status, int amount, int checkout) {
        return buildSnapshot(channel, status,
                new BigDecimal(amount), new BigDecimal(checkout));
    }

    private MonitorSnapshot buildSnapshot(String channel, String status, BigDecimal amount, BigDecimal checkout) {
        MonitorSnapshot s = new MonitorSnapshot();
        s.setSnapshotChannelCode(channel);
        s.setSnapshotCheckStatus(status);
        s.setSnapshotCiticAmount(amount);
        s.setSnapshotCheckoutAmount(checkout);
        return s;
    }
}