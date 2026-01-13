// Subscription模型测试
import 'package:flutter_test/flutter_test.dart';
import 'package:calender_app/models/subscription.dart';

void main() {
  group('Subscription', () {
    test('should create subscription with Subscription.create', () {
      final subscription = Subscription.create(
        name: '测试订阅',
        url: 'https://example.com/calendar.ics',
        color: 0xFF1976D2,
      );

      expect(subscription.name, '测试订阅');
      expect(subscription.url, 'https://example.com/calendar.ics');
      expect(subscription.color, 0xFF1976D2);
      expect(subscription.isActive, true);
      expect(subscription.id, isNotEmpty);
    });

    test('should serialize to map correctly', () {
      final now = DateTime.now();
      final subscription = Subscription(
        id: 'sub-123',
        name: '测试订阅',
        url: 'https://example.com/calendar.ics',
        color: 0xFF1976D2,
        isActive: true,
        lastSync: now,
        lastSyncStatus: SyncStatus.success,
        syncInterval: const Duration(hours: 1),
        eventCount: 10,
        createdAt: now,
        updatedAt: now,
      );

      final map = subscription.toMap();

      expect(map['id'], 'sub-123');
      expect(map['name'], '测试订阅');
      expect(map['url'], 'https://example.com/calendar.ics');
      expect(map['color'], 0xFF1976D2);
      expect(map['is_active'], 1);
      expect(map['last_sync_status'], SyncStatus.success.index);
      expect(map['sync_interval'], 3600000);
      expect(map['event_count'], 10);
    });

    test('should deserialize from map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'sub-123',
        'name': '测试订阅',
        'url': 'https://example.com/calendar.ics',
        'color': 0xFF1976D2,
        'is_active': 1,
        'last_sync': now.millisecondsSinceEpoch,
        'last_sync_status': SyncStatus.success.index,
        'last_sync_error': null,
        'sync_interval': 3600000,
        'event_count': 10,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final subscription = Subscription.fromMap(map);

      expect(subscription.id, 'sub-123');
      expect(subscription.name, '测试订阅');
      expect(subscription.url, 'https://example.com/calendar.ics');
      expect(subscription.isActive, true);
      expect(subscription.lastSyncStatus, SyncStatus.success);
      expect(subscription.syncInterval, const Duration(hours: 1));
      expect(subscription.eventCount, 10);
    });

    test('copyWith should create new instance with updated fields', () {
      final subscription = Subscription.create(
        name: '原始名称',
        url: 'https://example.com/calendar.ics',
      );

      final updated = subscription.copyWith(name: '新名称');

      expect(updated.name, '新名称');
      expect(updated.id, subscription.id);
      expect(updated.url, subscription.url);
    });

    test('syncIntervalText should return correct text', () {
      expect(
        Subscription.create(
          name: 'Test',
          url: 'https://example.com',
          syncInterval: Duration.zero,
        ).syncIntervalText,
        '手动',
      );

      expect(
        Subscription.create(
          name: 'Test',
          url: 'https://example.com',
          syncInterval: const Duration(hours: 1),
        ).syncIntervalText,
        '每小时',
      );

      expect(
        Subscription.create(
          name: 'Test',
          url: 'https://example.com',
          syncInterval: const Duration(days: 1),
        ).syncIntervalText,
        '每天',
      );
    });

    test('lastSyncText should return correct text', () {
      final now = DateTime.now();

      expect(
        Subscription.create(name: 'Test', url: 'https://example.com').lastSyncText,
        '从未同步',
      );

      expect(
        Subscription.create(name: 'Test', url: 'https://example.com')
            .copyWith(lastSync: now)
            .lastSyncText,
        '刚刚同步',
      );

      expect(
        Subscription.create(name: 'Test', url: 'https://example.com')
            .copyWith(lastSync: now.subtract(const Duration(hours: 2)))
            .lastSyncText,
        '2小时前同步',
      );
    });

    test('needsSync should return correct value', () {
      final now = DateTime.now();

      // 从未同步，需要同步
      expect(
        Subscription.create(
          name: 'Test',
          url: 'https://example.com',
          syncInterval: const Duration(hours: 1),
        ).needsSync,
        true,
      );

      // 禁用的订阅不需要同步
      expect(
        Subscription.create(
          name: 'Test',
          url: 'https://example.com',
          isActive: false,
        ).needsSync,
        false,
      );

      // 手动同步的不需要自动同步
      expect(
        Subscription.create(
          name: 'Test',
          url: 'https://example.com',
          syncInterval: Duration.zero,
        ).needsSync,
        false,
      );

      // 刚同步过的不需要同步
      expect(
        Subscription.create(
          name: 'Test',
          url: 'https://example.com',
          syncInterval: const Duration(hours: 1),
        ).copyWith(lastSync: now).needsSync,
        false,
      );

      // 超过间隔的需要同步
      expect(
        Subscription.create(
          name: 'Test',
          url: 'https://example.com',
          syncInterval: const Duration(hours: 1),
        ).copyWith(lastSync: now.subtract(const Duration(hours: 2))).needsSync,
        true,
      );
    });
  });

  group('SyncIntervalOption', () {
    test('presets should contain common options', () {
      expect(SyncIntervalOption.presets.length, greaterThan(3));

      final labels = SyncIntervalOption.presets.map((o) => o.label).toList();
      expect(labels, contains('手动'));
      expect(labels, contains('每小时'));
      expect(labels, contains('每天'));
    });

    test('findByDuration should find matching option', () {
      final option = SyncIntervalOption.findByDuration(const Duration(hours: 1));
      expect(option, isNotNull);
      expect(option!.label, '每小时');
    });

    test('findByDuration should return null for non-preset', () {
      final option = SyncIntervalOption.findByDuration(const Duration(hours: 3));
      expect(option, isNull);
    });
  });

  group('SyncResult', () {
    test('should create sync result', () {
      const result = SyncResult(
        syncedCount: 10,
        addedCount: 5,
        updatedCount: 3,
        deletedCount: 2,
      );

      expect(result.syncedCount, 10);
      expect(result.addedCount, 5);
      expect(result.isSuccess, true);
      expect(result.hasErrors, false);
    });

    test('hasErrors should return true when errors exist', () {
      const result = SyncResult(
        syncedCount: 10,
        errors: ['Error 1'],
      );

      expect(result.hasErrors, true);
      expect(result.isSuccess, false);
    });

    test('toString should return formatted string', () {
      const result = SyncResult(
        syncedCount: 10,
        addedCount: 5,
        updatedCount: 3,
      );

      expect(result.toString(), contains('10'));
      expect(result.toString(), contains('5'));
    });
  });
}

