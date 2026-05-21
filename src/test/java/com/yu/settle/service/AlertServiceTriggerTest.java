package com.yu.settle.service;

import com.yu.settle.dao.*;
import com.yu.settle.manage.AlertManage;
import com.yu.settle.manage.MonitorManage;
import com.yu.settle.model.AlertRule;
import com.yu.settle.model.MonitorSnapshot;
import com.yu.settle.model.NotifyContact;
import com.yu.settle.model.NotifyGroup;
import com.yu.settle.util.NotifyUtil;
import com.yu.settle.util.SettleConstant;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Collections;

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
    @DisplayName("WAITING/IN_PROGRESS/NORMAL statuses do NOT trigger alerts")
    void nonAlertStatusesSkipped() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_WAITING);
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(Collections.singletonList(snap));
        alertService.triggerAlerts("2026-05-21", false);
        verify(alertRuleDao, never()).selectEnabledRulesByType(anyString());
    }

    @Test
    @DisplayName("MISSING status -> matches rule -> sends alert -> saves record")
    void missingTriggersAlert() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotId("snap1");
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_MISSING);
        snap.setSnapshotCiticAmount(new BigDecimal("5000"));
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(Collections.singletonList(snap));

        AlertRule rule = new AlertRule();
        rule.setRuleId("rule1");
        rule.setRuleNotifyGroupId("group1");
        rule.setRuleCooldownMinutes(120);
        when(alertRuleDao.selectEnabledRulesByType(SettleConstant.ALERT_TYPE_MISSING))
                .thenReturn(Collections.singletonList(rule));
        when(alertRecordDao.selectRecentRecordByChannelAndType(
                eq("MTTO"), eq(SettleConstant.ALERT_TYPE_MISSING), eq(120)))
                .thenReturn(null);

        NotifyGroup group = new NotifyGroup();
        group.setGroupId("group1");
        group.setGroupIsEnabled(1);
        group.setGroupWechatWebhookUrl("https://qyapi.weixin.qq.com/webhook/test");
        when(notifyGroupDao.selectNotifyGroupById("group1")).thenReturn(group);

        NotifyContact contact = new NotifyContact();
        contact.setContactWechatUserId("user1");
        when(notifyContactDao.selectContactsByGroupId("group1")).thenReturn(Collections.singletonList(contact));

        when(notifyUtil.buildAlertMessage(any(), anyString())).thenReturn("test message");
        when(notifyUtil.sendWechatWebhook(anyString(), anyString(), anyList())).thenReturn(true);

        alertService.triggerAlerts("2026-05-21", false);

        verify(alertManage).insertAlertRecord(any());
        verify(monitorManage).updateMonitorSnapshot(any());
    }

    @Test
    @DisplayName("cooldown active -> no alert sent")
    void cooldownPreventsDuplicate() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotId("snap1");
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_MISSING);
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(Collections.singletonList(snap));

        AlertRule rule = new AlertRule();
        rule.setRuleId("rule1");
        rule.setRuleNotifyGroupId("group1");
        rule.setRuleCooldownMinutes(120);
        when(alertRuleDao.selectEnabledRulesByType(SettleConstant.ALERT_TYPE_MISSING))
                .thenReturn(Collections.singletonList(rule));
        when(alertRecordDao.selectRecentRecordByChannelAndType(
                eq("MTTO"), eq(SettleConstant.ALERT_TYPE_MISSING), eq(120)))
                .thenReturn(new com.yu.settle.model.AlertRecord()); // recent record exists

        alertService.triggerAlerts("2026-05-21", false);

        verify(notifyUtil, never()).sendWechatWebhook(anyString(), anyString(), anyList());
        verify(alertManage, never()).insertAlertRecord(any());
    }

    @Test
    @DisplayName("force=true bypasses cooldown")
    void forceBypassesCooldown() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotId("snap1");
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_MISSING);
        snap.setSnapshotCiticAmount(new BigDecimal("5000"));
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(Collections.singletonList(snap));

        AlertRule rule = new AlertRule();
        rule.setRuleId("rule1");
        rule.setRuleNotifyGroupId("group1");
        rule.setRuleCooldownMinutes(120);
        when(alertRuleDao.selectEnabledRulesByType(SettleConstant.ALERT_TYPE_MISSING))
                .thenReturn(Collections.singletonList(rule));
        // cooldown check is NOT called when force=true

        NotifyGroup group = new NotifyGroup();
        group.setGroupId("group1");
        group.setGroupIsEnabled(1);
        group.setGroupWechatWebhookUrl("https://qyapi.weixin.qq.com/webhook/test");
        when(notifyGroupDao.selectNotifyGroupById("group1")).thenReturn(group);
        when(notifyContactDao.selectContactsByGroupId("group1")).thenReturn(Collections.singletonList(new NotifyContact()));
        when(notifyUtil.buildAlertMessage(any(), anyString())).thenReturn("test");
        when(notifyUtil.sendWechatWebhook(anyString(), anyString(), anyList())).thenReturn(true);

        alertService.triggerAlerts("2026-05-21", true);
        verify(alertManage).insertAlertRecord(any());
    }

    @Test
    @DisplayName("disabled notify group -> alert skipped")
    void disabledGroupSkips() {
        MonitorSnapshot snap = new MonitorSnapshot();
        snap.setSnapshotId("snap1");
        snap.setSnapshotDate("2026-05-21");
        snap.setSnapshotChannelCode("MTTO");
        snap.setSnapshotCheckStatus(SettleConstant.CHECK_STATUS_MISSING);
        when(monitorSnapshotDao.selectSnapshotList(any())).thenReturn(Collections.singletonList(snap));

        AlertRule rule = new AlertRule();
        rule.setRuleId("rule1");
        rule.setRuleNotifyGroupId("group1");
        when(alertRuleDao.selectEnabledRulesByType(SettleConstant.ALERT_TYPE_MISSING))
                .thenReturn(Collections.singletonList(rule));
        when(alertRecordDao.selectRecentRecordByChannelAndType(anyString(), anyString(), anyInt()))
                .thenReturn(null);

        NotifyGroup group = new NotifyGroup();
        group.setGroupId("group1");
        group.setGroupIsEnabled(0); // disabled
        when(notifyGroupDao.selectNotifyGroupById("group1")).thenReturn(group);

        alertService.triggerAlerts("2026-05-21", false);
        verify(notifyUtil, never()).sendWechatWebhook(anyString(), anyString(), anyList());
    }
}