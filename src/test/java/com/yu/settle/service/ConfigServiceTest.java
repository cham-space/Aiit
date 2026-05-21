package com.yu.settle.service;

import com.yu.settle.dao.ChannelConfigDao;
import com.yu.settle.dao.NotifyContactDao;
import com.yu.settle.dao.NotifyGroupDao;
import com.yu.settle.manage.ConfigManage;
import com.yu.settle.model.ChannelConfig;
import com.yu.settle.model.NotifyContact;
import com.yu.settle.model.NotifyGroup;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("ConfigService")
class ConfigServiceTest {

    @Mock
    private ChannelConfigDao channelConfigDao;

    @Mock
    private NotifyGroupDao notifyGroupDao;

    @Mock
    private NotifyContactDao notifyContactDao;

    @Mock
    private ConfigManage configManage;

    @InjectMocks
    private ConfigService configService;

    // ========== ChannelConfig ==========

    @Test
    @DisplayName("selectChannelConfigList() delegates to DAO and returns expected list")
    void selectChannelConfigList() {
        ChannelConfig param = new ChannelConfig();
        List<ChannelConfig> expected = Collections.singletonList(new ChannelConfig());
        when(channelConfigDao.selectChannelConfigList(param)).thenReturn(expected);

        List<ChannelConfig> result = configService.selectChannelConfigList(param);

        assertEquals(expected, result);
        verify(channelConfigDao).selectChannelConfigList(param);
    }

    @Test
    @DisplayName("selectChannelConfigList() returns empty list when DAO returns empty")
    void selectChannelConfigListEmpty() {
        ChannelConfig param = new ChannelConfig();
        List<ChannelConfig> expected = Collections.emptyList();
        when(channelConfigDao.selectChannelConfigList(param)).thenReturn(expected);

        List<ChannelConfig> result = configService.selectChannelConfigList(param);

        assertEquals(0, result.size());
        verify(channelConfigDao).selectChannelConfigList(param);
    }

    @Test
    @DisplayName("saveChannelConfig() delegates to configManage.insertOrUpdateChannelConfig()")
    void saveChannelConfig() {
        ChannelConfig config = new ChannelConfig();

        configService.saveChannelConfig(config);

        verify(configManage).insertOrUpdateChannelConfig(config);
    }

    // ========== NotifyGroup ==========

    @Test
    @DisplayName("selectNotifyGroupList() delegates to DAO and returns expected list")
    void selectNotifyGroupList() {
        NotifyGroup param = new NotifyGroup();
        NotifyGroup group = new NotifyGroup();
        List<NotifyGroup> expected = Collections.singletonList(group);
        when(notifyGroupDao.selectNotifyGroupList(param)).thenReturn(expected);

        List<NotifyGroup> result = configService.selectNotifyGroupList(param);

        assertEquals(expected, result);
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(group, result.get(0));
        verify(notifyGroupDao).selectNotifyGroupList(param);
    }

    @Test
    @DisplayName("selectNotifyGroupList() returns empty list when DAO returns empty")
    void selectNotifyGroupListEmpty() {
        NotifyGroup param = new NotifyGroup();
        when(notifyGroupDao.selectNotifyGroupList(param)).thenReturn(Collections.emptyList());

        List<NotifyGroup> result = configService.selectNotifyGroupList(param);

        assertEquals(0, result.size());
        verify(notifyGroupDao).selectNotifyGroupList(param);
    }

    @Test
    @DisplayName("saveNotifyGroup() delegates to configManage.insertOrUpdateNotifyGroup()")
    void saveNotifyGroup() {
        NotifyGroup group = new NotifyGroup();

        configService.saveNotifyGroup(group);

        verify(configManage).insertOrUpdateNotifyGroup(group);
    }

    // ========== NotifyContact ==========

    @Test
    @DisplayName("selectNotifyContactList() delegates to DAO and returns expected list")
    void selectNotifyContactList() {
        NotifyContact param = new NotifyContact();
        NotifyContact contact = new NotifyContact();
        List<NotifyContact> expected = Collections.singletonList(contact);
        when(notifyContactDao.selectNotifyContactList(param)).thenReturn(expected);

        List<NotifyContact> result = configService.selectNotifyContactList(param);

        assertEquals(expected, result);
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(contact, result.get(0));
        verify(notifyContactDao).selectNotifyContactList(param);
    }

    @Test
    @DisplayName("selectNotifyContactList() returns empty list when DAO returns empty")
    void selectNotifyContactListEmpty() {
        NotifyContact param = new NotifyContact();
        when(notifyContactDao.selectNotifyContactList(param)).thenReturn(Collections.emptyList());

        List<NotifyContact> result = configService.selectNotifyContactList(param);

        assertEquals(0, result.size());
        verify(notifyContactDao).selectNotifyContactList(param);
    }

    @Test
    @DisplayName("saveNotifyContact() delegates to configManage.insertOrUpdateNotifyContact()")
    void saveNotifyContact() {
        NotifyContact contact = new NotifyContact();

        configService.saveNotifyContact(contact);

        verify(configManage).insertOrUpdateNotifyContact(contact);
    }
}