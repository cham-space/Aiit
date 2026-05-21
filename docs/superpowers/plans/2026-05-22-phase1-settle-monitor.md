# Phase 1 — 资金归集监控与预警系统 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标:** 验证 Phase 1 已实现的全部功能代码，补充测试覆盖、配置 Nacos 注册中心，逐项确认 16 条 PRD 验收标准通过

**架构:** Spring Boot 2.3.12 分层架构 — Controller → Service → Manage → DAO → Model，定时任务由 SettleScheduler 驱动 MonitorService → AlertService → HealthService 三个核心服务链

**技术栈:** Java 1.8, Spring Boot 2.3.12, Maven 3.x, JUnit 5 + Mockito, MySQL, Nacos, 企业微信 Webhook

---

### Task 1: 运行现有测试套件，建立基线

**文件:**
- 无新建文件

- [ ] **Step 1: 运行全部现有测试**

```bash
mvn test
```

Expected: 全部现有测试通过（约 100+ 个测试用例），零失败。

- [ ] **Step 2: 检查测试报告确认测试数量**

```bash
find target/surefire-reports -name "*.xml" -exec grep 'tests=' {} \; | head -20
```

Expected: 显示各测试类的 tests/errors/failures/skipped 统计。

---

### Task 2: Nacos 注册中心配置

**文件:**
- 修改: `src/main/resources/application.properties` 或 `application.yml`

- [ ] **Step 1: 确认 Nacos 配置文件位置**

```bash
find src/main/resources -name "application*" -o -name "bootstrap*" | head -10
```

- [ ] **Step 2: 添加 Nacos 注册中心配置**

在 `src/main/resources/application.properties` 中添加：

```properties
# Nacos 注册中心
spring.cloud.nacos.discovery.server-addr=47.93.28.223:8848
spring.cloud.nacos.discovery.username=nacos
spring.cloud.nacos.discovery.password=yn@20240122.nacos
spring.cloud.nacos.discovery.namespace=2096f036-1a21-41d1-a2b9-2ccffee13599
```

如果项目使用 `bootstrap.properties` 则写入该文件。

- [ ] **Step 3: 运行 Maven 构建确认 Nacos 配置不破坏编译**

```bash
mvn clean compile
```

Expected: BUILD SUCCESS

- [ ] **Step 4: 提交**

```bash
git add src/main/resources/
git commit -m "feat: configure Nacos registration center"
```

---

### Task 3: Dashboard 聚合逻辑测试

**文件:**
- 新建: `src/test/java/com/yu/settle/service/MonitorServiceDashboardTest.java`
- 现有: `src/main/java/com/yu/settle/service/MonitorService.java:62-145`

- [ ] **Step 1: 编写 buildDashboardSummary 单元测试 — 全部正常**

```java
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
    @DisplayName("全部正常 → HEALTHY, healthPct=100")
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
    @DisplayName("一个 MISSING → WARNING")
    void oneMissingCausesWarning() {
        MonitorSnapshot s1 = buildSnapshot("MTTO", SettleConstant.CHECK_STATUS_NORMAL, 1000, 1000);
        MonitorSnapshot s2 = buildSnapshot("ELM", SettleConstant.CHECK_STATUS_MISSING, null, null);
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Arrays.asList(s1, s2));
        assertEquals("WARNING", summary.getOverallStatus());
        assertEquals(50, summary.getHealthPct()); // 1 normal / 2 total
        assertEquals(1, summary.getMissingCount());
    }

    @Test
    @DisplayName("空渠道列表 → healthPct=0, totalCount=0")
    void emptyChannelList() {
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Collections.emptyList());
        assertEquals(0, summary.getTotalCount());
        assertEquals(0, summary.getHealthPct());
        assertEquals("HEALTHY", summary.getOverallStatus());
    }

    @Test
    @DisplayName("WAITING + IN_PROGRESS 计入健康度")
    void waitingCountsAsHealthy() {
        MonitorSnapshot s1 = buildSnapshot("MTTO", SettleConstant.CHECK_STATUS_WAITING, null, null);
        MonitorSnapshot s2 = buildSnapshot("ELM", SettleConstant.CHECK_STATUS_IN_PROGRESS, 1500, 1500);
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Arrays.asList(s1, s2));
        assertEquals(2, summary.getWaitingCount()); // WAITING + IN_PROGRESS
        assertEquals(100, summary.getHealthPct());   // 两者都算健康
    }

    @Test
    @DisplayName("全局金额聚合正确（全量求和）")
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
    @DisplayName("同比/环比均值：无数据渠道不参与计算")
    void avgChangeExcludesNulls() {
        MonitorSnapshot s1 = buildSnapshot("MTTO", SettleConstant.CHECK_STATUS_NORMAL, 1000, 1000);
        s1.setSnapshotAmountYoyChange(new BigDecimal("0.10"));
        MonitorSnapshot s2 = buildSnapshot("ELM", SettleConstant.CHECK_STATUS_NORMAL, 2000, 2000);
        s2.setSnapshotAmountYoyChange(new BigDecimal("0.20"));
        MonitorSnapshot s3 = buildSnapshot("DYGP", SettleConstant.CHECK_STATUS_MISSING, null, null);
        DashboardSummary summary = monitorService.buildDashboardSummary(
                "2026-05-21", Arrays.asList(s1, s2, s3));
        assertEquals(new BigDecimal("0.1500"), summary.getAvgYoyChange()); // (0.10+0.20)/2
        assertNull(summary.getAvgWowChange()); // no WOW data
    }

    private MonitorSnapshot buildSnapshot(String channel, String status, Integer amount, Integer checkout) {
        return buildSnapshot(channel, status,
                amount != null ? new BigDecimal(amount) : null,
                checkout != null ? new BigDecimal(checkout) : null);
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
```

- [ ] **Step 2: 运行测试**

```bash
mvn test -Dtest=MonitorServiceDashboardTest
```

Expected: 6 tests PASS

- [ ] **Step 3: 提交**

```bash
git add src/test/java/com/yu/settle/service/MonitorServiceDashboardTest.java
git commit -m "test: add buildDashboardSummary unit tests — status counts, health%, amount aggregation"
```

---

### Task 4: AlertService triggerAlerts 流程测试

**文件:**
- 新建: `src/test/java/com/yu/settle/service/AlertServiceTriggerTest.java`

- [ ] **Step 1: 编写 triggerAlerts 规则匹配与冷却期测试**

```java
package com.yu.settle.service;

import com.yu.settle.dao.*;
import com.yu.settle.manage.AlertManage;
import com.yu.settle.manage.MonitorManage;
import com.yu.settle.model.AlertRecord;
import com.yu.settle.model.AlertRule;
import com.yu.settle.model.MonitorSnapshot;
import com.yu.settle.model.NotifyContact;
import com.yu.settle.model.NotifyGroup;
import com.yu.settle.util.NotifyUtil;
import com.yu.settle.util.SettleConstant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("AlertService — triggerAlerts flow")
class AlertServiceTriggerTest {

    @Mock private MonitorSnapshotDao monitorSnapshotDao;
    @Mock private AlertRuleDao alertRuleDao;
    @Mock private AlertRecordDao alertRecordDao;
    @Mock private NotifyGroupDao notifyGroupDao;
    @Mock private NotifyContactDao notifyContactDao;
    @Mock private AlertManage alertManage;
    @Mock private MonitorManage monitorManage;
    @Mock private NotifyUtil notifyUtil;
    @Mock private MonitorService monitorService;

    @InjectMocks
    private AlertService alertService;

    @Test
    @DisplayName("WAITING/IN_PROGRESS/NORMAL 状态不触发预警")
    void nonAlertStatusesSkipped() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_WAITING);
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(List.of(snap));
        alertService.triggerAlerts("2026-05-21", false);
        verify(alertRuleDao, never()).selectEnabledRulesByType(anyString());
    }

    @Test
    @DisplayName("MISSING 状态 → 匹配规则 → 发送预警 → 记录")
    void missingTriggersAlert() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotId("snap1");
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_MISSING);
        snap.setSnapshotCiticAmount(new BigDecimal("5000"));
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(List.of(snap));

        AlertRule rule = new AlertRule();
        rule.setRuleId("rule1");
        rule.setRuleAlertType(SettleConstant.ALERT_TYPE_MISSING);
        rule.setRuleNotifyGroupId("group1");
        rule.setRuleCooldownMinutes(120);
        when(alertRuleDao.selectEnabledRulesByType(SettleConstant.ALERT_TYPE_MISSING))
                .thenReturn(List.of(rule));
        when(alertRecordDao.selectRecentRecordByChannelAndType(eq("MTTO"), eq(SettleConstant.ALERT_TYPE_MISSING), eq(120)))
                .thenReturn(null); // no recent record → pass cooldown

        NotifyGroup group = new NotifyGroup();
        group.setGroupId("group1");
        group.setGroupIsEnabled(1);
        group.setGroupWechatWebhookUrl("https://qyapi.weixin.qq.com/webhook/test");
        when(notifyGroupDao.selectNotifyGroupById("group1")).thenReturn(group);

        NotifyContact contact = new NotifyContact();
        contact.setContactWechatUserId("user1");
        when(notifyContactDao.selectContactsByGroupId("group1")).thenReturn(List.of(contact));

        when(notifyUtil.buildAlertMessage(any(), anyString())).thenReturn("test message");
        when(notifyUtil.sendWechatWebhook(anyString(), anyString(), anyList())).thenReturn(true);

        alertService.triggerAlerts("2026-05-21", false);

        // verify alert record was saved
        verify(alertManage).insertAlertRecord(any());
        // verify snapshot alertSent updated
        verify(monitorManage).updateMonitorSnapshot(any());
    }

    @Test
    @DisplayName("冷却期内不重复发送")
    void cooldownPreventsDuplicate() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotId("snap1");
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_MISSING);
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(List.of(snap));

        AlertRule rule = new AlertRule();
        rule.setRuleId("rule1");
        rule.setRuleAlertType(SettleConstant.ALERT_TYPE_MISSING);
        rule.setRuleNotifyGroupId("group1");
        rule.setRuleCooldownMinutes(120);
        when(alertRuleDao.selectEnabledRulesByType(SettleConstant.ALERT_TYPE_MISSING))
                .thenReturn(List.of(rule));

        // 存在最近记录 → 冷却期内，跳过
        AlertRecord recentRecord = new AlertRecord();
        when(alertRecordDao.selectRecentRecordByChannelAndType(eq("MTTO"), eq(SettleConstant.ALERT_TYPE_MISSING), eq(120)))
                .thenReturn(recentRecord);

        alertService.triggerAlerts("2026-05-21", false);

        // 不应发送预警
        verify(notifyUtil, never()).sendWechatWebhook(anyString(), anyString(), anyList());
        verify(alertManage, never()).insertAlertRecord(any());
    }

    @Test
    @DisplayName("force=true 跳过冷却期")
    void forceBypassesCooldown() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotId("snap1");
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_MISSING);
        snap.setSnapshotCiticAmount(new BigDecimal("5000"));
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(List.of(snap));

        AlertRule rule = new AlertRule();
        rule.setRuleId("rule1");
        rule.setRuleAlertType(SettleConstant.ALERT_TYPE_MISSING);
        rule.setRuleNotifyGroupId("group1");
        rule.setRuleCooldownMinutes(120);
        when(alertRuleDao.selectEnabledRulesByType(SettleConstant.ALERT_TYPE_MISSING))
                .thenReturn(List.of(rule));

        // force=true 时不检查冷却期
        NotifyGroup group = new NotifyGroup();
        group.setGroupId("group1");
        group.setGroupIsEnabled(1);
        group.setGroupWechatWebhookUrl("https://qyapi.weixin.qq.com/webhook/test");
        when(notifyGroupDao.selectNotifyGroupById("group1")).thenReturn(group);
        when(notifyContactDao.selectContactsByGroupId("group1")).thenReturn(List.of(new NotifyContact()));
        when(notifyUtil.buildAlertMessage(any(), anyString())).thenReturn("test");
        when(notifyUtil.sendWechatWebhook(anyString(), anyString(), anyList())).thenReturn(true);

        alertService.triggerAlerts("2026-05-21", true);
        verify(alertManage).insertAlertRecord(any());
    }

    @Test
    @DisplayName("通知组禁用时不发送")
    void disabledGroupSkips() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotId("snap1");
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_MISSING);
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(List.of(snap));

        AlertRule rule = new AlertRule();
        rule.setRuleId("rule1");
        rule.setRuleAlertType(SettleConstant.ALERT_TYPE_MISSING);
        rule.setRuleNotifyGroupId("group1");
        when(alertRuleDao.selectEnabledRulesByType(SettleConstant.ALERT_TYPE_MISSING))
                .thenReturn(List.of(rule));
        when(alertRecordDao.selectRecentRecordByChannelAndType(anyString(), anyString(), anyInt()))
                .thenReturn(null);

        NotifyGroup group = new NotifyGroup();
        group.setGroupId("group1");
        group.setGroupIsEnabled(0); // disabled!
        when(notifyGroupDao.selectNotifyGroupById("group1")).thenReturn(group);

        alertService.triggerAlerts("2026-05-21", false);
        verify(notifyUtil, never()).sendWechatWebhook(anyString(), anyString(), anyList());
    }
}
```

- [ ] **Step 2: 运行测试**

```bash
mvn test -Dtest=AlertServiceTriggerTest
```

Expected: 5 tests PASS

- [ ] **Step 3: 提交**

```bash
git add src/test/java/com/yu/settle/service/AlertServiceTriggerTest.java
git commit -m "test: add triggerAlerts flow tests — rule matching, cooldown, force mode, disabled group"
```

---

### Task 5: ConfigService 测试

**文件:**
- 新建: `src/test/java/com/yu/settle/service/ConfigServiceTest.java`
- 现有: `src/main/java/com/yu/settle/service/ConfigService.java`

- [ ] **Step 1: 阅读 ConfigService 源码**

```bash
cat src/main/java/com/yu/settle/service/ConfigService.java
```

- [ ] **Step 2: 编写 ConfigService CRUD 测试**

```java
package com.yu.settle.service;

import com.yu.settle.dao.*;
import com.yu.settle.manage.ConfigManage;
import com.yu.settle.model.ChannelConfig;
import com.yu.settle.model.NotifyContact;
import com.yu.settle.model.NotifyGroup;
import com.yu.settle.model.Operator;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ConfigService")
class ConfigServiceTest {

    @Mock private ChannelConfigDao channelConfigDao;
    @Mock private NotifyGroupDao notifyGroupDao;
    @Mock private NotifyContactDao notifyContactDao;
    @Mock private ConfigManage configManage;

    @InjectMocks
    private ConfigService configService;

    @Test
    @DisplayName("selectChannelConfigList 委托 DAO")
    void selectChannelConfigList() {
        ChannelConfig param = new ChannelConfig();
        List<ChannelConfig> expected = List.of(new ChannelConfig());
        when(channelConfigDao.selectChannelConfigList(param)).thenReturn(expected);
        assertEquals(expected, configService.selectChannelConfigList(param));
    }

    @Test
    @DisplayName("saveChannelConfig 新增时生成 UUID")
    void saveChannelConfigNew() {
        ChannelConfig config = new ChannelConfig();
        config.setConfigChannelCode("TEST");
        configService.saveChannelConfig(config);
        assertNotNull(config.getConfigId());
        verify(configManage).insertOrUpdateChannelConfig(config);
    }

    @Test
    @DisplayName("saveNotifyGroup 新增时生成 UUID")
    void saveNotifyGroupNew() {
        NotifyGroup group = new NotifyGroup();
        configService.saveNotifyGroup(group);
        assertNotNull(group.getGroupId());
        verify(configManage).insertOrUpdateNotifyGroup(group);
    }

    @Test
    @DisplayName("saveNotifyContact 新增时生成 UUID")
    void saveNotifyContactNew() {
        NotifyContact contact = new NotifyContact();
        configService.saveNotifyContact(contact);
        assertNotNull(contact.getContactId());
        verify(configManage).insertOrUpdateNotifyContact(contact);
    }
}
```

- [ ] **Step 3: 运行测试**

```bash
mvn test -Dtest=ConfigServiceTest
```

Expected: All tests PASS

- [ ] **Step 4: 提交**

```bash
git add src/test/java/com/yu/settle/service/ConfigServiceTest.java
git commit -m "test: add ConfigService CRUD tests"
```

---

### Task 6: 运行完整测试套件并确认全部通过

**文件:**
- 无新建文件

- [ ] **Step 1: 运行全部测试**

```bash
mvn test
```

Expected: BUILD SUCCESS，所有测试全部通过，零失败。

- [ ] **Step 2: 确认测试总数**

```bash
grep -r "tests=" target/surefire-reports/*.xml | grep -oP 'tests="\K\d+'
```

---

### Task 7: 逐项验证 16 条 PRD 验收标准

**文件:**
- 无新建文件

对照 `specs/20260521-phase1-settle-monitor/prd.md` 第 六 章验收清单：

- [ ] AC-1: 定时任务 cron `0 0 9,12,15,18,21 * * ?` 在 SettleScheduler.scanAndAlert() 中
- [ ] AC-2: ChannelConfigDao 查询 7 个启用渠道，ELM_INSURE 不在配置表中
- [ ] AC-3: MonitorServiceTest.determineCheckStatus 覆盖全部 8 种状态
- [ ] AC-4: AlertServiceTest.determineAlertLevel 验证 CRITICAL/WARN/INFO 映射
- [ ] AC-5: AlertServiceTriggerTest.cooldownPreventsDuplicate 验证冷却期
- [ ] AC-6: NotifyUtilTest.buildAlertMessageContainsFields 验证消息格式
- [ ] AC-7: NotifyUtil.buildHealthBar 实现 10 格固定宽度 + 整数截断
- [ ] AC-8: MonitorServiceDashboardTest.avgChangeExcludesNulls 验证 null 排除
- [ ] AC-9: HookServiceTest 验证 401/429 响应码
- [ ] AC-10: SettleScheduler.calcHealthScore cron `0 30 1 * * ?`
- [ ] AC-11: HealthServiceTest.healthScoreFormula 验证 0-100 范围 + 2 位小数
- [ ] AC-12: MonitorService.scanDailyStatus 中 try-catch 包裹每个渠道
- [ ] AC-13: MonitorServiceTest.jdmsInGroup / businessInGroup 验证分组逻辑
- [ ] AC-14: MonitorServiceTest.computeAmountChanges null amount check
- [ ] AC-15: Nacos 配置已添加（Task 2）
- [ ] AC-16: `mvn test` 全部通过

---

### Task 8: 生成 specs/README.md 消除 Phase 0 警告

**文件:**
- 新建: `specs/README.md`

- [ ] **Step 1: 创建 specs 目录说明文件**

```
# OpenSpec 规格目录

本目录包含 AI Development Base 的 OpenSpec 变更规格文档。

- `prd/` — 产品需求文档模板
- `plan/` — 实现计划模板
- `api/` — API 合约模板
- `design/` — 设计规格模板
- `test/` — 测试策略模板
- `release/` — 发布/验证报告模板
```

- [ ] **Step 2: 提交**

```bash
git add specs/README.md
git commit -m "docs: add specs/README.md overview"
```

---

### Task 9: 最终验收 — 全量测试 + Phase 0/1 Gates

**文件:**
- 无新建文件

- [ ] **Step 1: 全量测试**

```bash
mvn test
```

Expected: BUILD SUCCESS

- [ ] **Step 2: Phase 0 Gates**

```bash
bash -c 'source .githooks/lib/gates.sh && run_phase_gates 0 ""'
```

Expected: ALL PASSED

- [ ] **Step 3: Phase 1 Gates**

```bash
bash -c 'source .githooks/lib/gates.sh && run_phase_gates 1 "20260521-phase1-settle-monitor"'
```

Expected: ALL PASSED

- [ ] **Step 4: 提交最终验收结果**

```bash
git add -A
git commit -m "chore: Phase 1 final verification — all gates pass, all tests pass"
```