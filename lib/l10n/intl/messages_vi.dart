// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a vi locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'vi';

  static String m0(count) =>
      "${Intl.plural(count, one: '1 ngày trước', other: '${count} ngày trước')}";

  static String m1(label) =>
      "Bạn có chắc muốn xóa ${label} đã chọn không?";

  static String m2(label) =>
      "Bạn có chắc muốn xóa ${label} hiện tại không?";

  static String m3(label) => "${label} chi tiết";

  static String m4(label) => "${label} không được để trống";

  static String m5(label) => "${label} hiện tại đã tồn tại";

  static String m6(count) =>
      "${Intl.plural(count, one: '1 giờ trước', other: '${count} giờ trước')}";

  static String m7(target) => "${target} là chính sách không hợp lệ";

  static String m8(proxyName) => "${proxyName} là proxy không hợp lệ";

  static String m9(providerName) =>
      "${providerName} là nguồn proxy không hợp lệ";

  static String m10(subRule) => "${subRule} là SUB_RULE không hợp lệ";

  static String m11(appName) =>
      "1. Mở Cài đặt hệ thống > Quyền riêng tư & Bảo mật\n2. Chọn Dịch vụ vị trí\n3. Tìm và chọn ${appName} trong danh sách bên phải\n\nSau khi hoàn tất, quay lại ứng dụng và sử dụng bình thường. Cảm ơn bạn đã hợp tác.";

  static String m12(count) =>
      "${Intl.plural(count, one: '1 phút trước', other: '${count} phút trước')}";

  static String m13(count) =>
      "${Intl.plural(count, one: '1 tháng trước', other: '${count} tháng trước')}";

  static String m14(label) => "Chưa có ${label}";

  static String m15(label) => "${label} phải là số";

  static String m16(label) => "${label} phải từ 1024 đến 49151";

  static String m17(count) => "Đã chọn ${count} mục";

  static String m18(label) => "${label} phải là URL";

  static String m19(count) =>
      "${Intl.plural(count, one: '1 năm trước', other: '${count} năm trước')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("Về ứng dụng"),
    "accessControl": MessageLookupByLibrary.simpleMessage("Kiểm soát truy cập"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Chỉ cho phép ứng dụng được chọn vào VPN",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "Cấu hình quyền truy cập proxy của ứng dụng",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Ứng dụng được chọn sẽ bị loại khỏi VPN",
    ),
    "accessControlSettings": MessageLookupByLibrary.simpleMessage(
      "Cài đặt kiểm soát truy cập",
    ),
    "action_mode": MessageLookupByLibrary.simpleMessage("Đổi chế độ"),
    "action_proxy": MessageLookupByLibrary.simpleMessage("Proxy hệ thống"),
    "action_start": MessageLookupByLibrary.simpleMessage("Bật/Tắt"),
    "action_tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "action_view": MessageLookupByLibrary.simpleMessage("Hiện/Ẩn"),
    "add": MessageLookupByLibrary.simpleMessage("Thêm"),
    "addProfile": MessageLookupByLibrary.simpleMessage("Thêm cấu hình"),
    "addProxies": MessageLookupByLibrary.simpleMessage("Thêm proxy"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("Thêm nhóm proxy"),
    "addProxyProviders": MessageLookupByLibrary.simpleMessage("Thêm nguồn proxy"),
    "addRule": MessageLookupByLibrary.simpleMessage("Thêm quy tắc"),
    "addSsid": MessageLookupByLibrary.simpleMessage("Thêm SSID"),
    "address": MessageLookupByLibrary.simpleMessage("Địa chỉ"),
    "addressHelp": MessageLookupByLibrary.simpleMessage("Địa chỉ máy chủ WebDAV"),
    "addressTip": MessageLookupByLibrary.simpleMessage("Vui lòng nhập địa chỉ WebDAV hợp lệ"),
    "advancedConfig": MessageLookupByLibrary.simpleMessage("Cấu hình nâng cao"),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage(
      "Cung cấp các tuỳ chọn cấu hình đa dạng",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("Đồng ý"),
    "allowBypass": MessageLookupByLibrary.simpleMessage(
      "Cho phép ứng dụng bỏ qua VPN",
    ),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "Một số ứng dụng có thể bỏ qua VPN khi bật",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("Cho phép LAN"),
    "allowLanDesc": MessageLookupByLibrary.simpleMessage(
      "Cho phép kết nối proxy qua LAN",
    ),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage("Thêm DNS hệ thống"),
    "appendSystemDnsTip": MessageLookupByLibrary.simpleMessage(
      "Bắt buộc thêm DNS hệ thống vào cấu hình",
    ),
    "app": MessageLookupByLibrary.simpleMessage("Ứng dụng"),
    "application": MessageLookupByLibrary.simpleMessage("Ứng dụng"),
    "applicationDesc": MessageLookupByLibrary.simpleMessage(
      "Chỉnh sửa cài đặt liên quan đến ứng dụng",
    ),
    "authorized": MessageLookupByLibrary.simpleMessage("Đã uỷ quyền"),
    "auto": MessageLookupByLibrary.simpleMessage("Tự động"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage("Tự động kiểm tra cập nhật"),
    "autoCheckUpdateDesc": MessageLookupByLibrary.simpleMessage(
      "Tự động kiểm tra cập nhật khi khởi động ứng dụng",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage(
      "Tự động đóng kết nối",
    ),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "Tự động đóng kết nối sau khi đổi node",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("Khởi động cùng hệ thống"),
    "autoLaunchDesc": MessageLookupByLibrary.simpleMessage("Khởi động theo hệ thống"),
    "autoRun": MessageLookupByLibrary.simpleMessage("Tự động chạy"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "Tự động chạy khi mở ứng dụng",
    ),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage("Tự động đặt DNS hệ thống"),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("Tự động cập nhật"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Khoảng thời gian cập nhật tự động (phút)",
    ),
    "backup": MessageLookupByLibrary.simpleMessage("Sao lưu"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage("Sao lưu & Khôi phục"),
    "backupAndRestoreDesc": MessageLookupByLibrary.simpleMessage(
      "Đồng bộ dữ liệu qua WebDAV hoặc file",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("Sao lưu thành công"),
    "basicConfig": MessageLookupByLibrary.simpleMessage("Cấu hình cơ bản"),
    "basicConfigDesc": MessageLookupByLibrary.simpleMessage(
      "Chỉnh sửa cấu hình cơ bản toàn cục",
    ),
    "basicInfo": MessageLookupByLibrary.simpleMessage("Thông tin cơ bản"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("Chiến lược cơ bản"),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "Để đảm bảo hoạt động nền, vui lòng tắt tối ưu hoá pin cho ứng dụng này.",
    ),
    "batteryOptimizationStatusTip": MessageLookupByLibrary.simpleMessage(
      "Bị ảnh hưởng bởi hệ thống, trạng thái này có thể không luôn chính xác.",
    ),
    "bind": MessageLookupByLibrary.simpleMessage("Liên kết"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("Bỏ qua tên miền"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Chỉ có hiệu lực khi bật proxy hệ thống",
    ),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "Bộ nhớ đệm bị hỏng. Bạn có muốn xoá không?",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Hủy"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("Bỏ chọn tất cả"),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("Kiểm tra cập nhật"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage(
      "Ứng dụng hiện tại đã là phiên bản mới nhất",
    ),
    "clearData": MessageLookupByLibrary.simpleMessage("Xoá dữ liệu"),
    "clipboardExport": MessageLookupByLibrary.simpleMessage("Xuất clipboard"),
    "clipboardImport": MessageLookupByLibrary.simpleMessage("Nhập clipboard"),
    "color": MessageLookupByLibrary.simpleMessage("Màu sắc"),
    "colorSchemes": MessageLookupByLibrary.simpleMessage("Bảng màu"),
    "columns": MessageLookupByLibrary.simpleMessage("Cột"),
    "compatible": MessageLookupByLibrary.simpleMessage("Chế độ tương thích"),
    "confirm": MessageLookupByLibrary.simpleMessage("Xác nhận"),
    "configDataDetected": MessageLookupByLibrary.simpleMessage(
      "Phát hiện dữ liệu trong cấu hình",
    ),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn xoá tất cả dữ liệu không?",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn xóa nhóm proxy hiện tại không?",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn thoát cửa sổ hiện tại không?",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn buộc lõi bị lỗi không?",
    ),
    "confirmOverwriteTip": MessageLookupByLibrary.simpleMessage(
      "Dữ liệu hiện có sẽ bị ghi đè sau khi xác nhận",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("Đã kết nối"),
    "connecting": MessageLookupByLibrary.simpleMessage("Đang kết nối..."),
    "connection": MessageLookupByLibrary.simpleMessage("Kết nối"),
    "connections": MessageLookupByLibrary.simpleMessage("Kết nối"),
    "connectionsDesc": MessageLookupByLibrary.simpleMessage(
      "Xem dữ liệu kết nối hiện tại",
    ),
    "connectivity": MessageLookupByLibrary.simpleMessage("Kết nối："),
    "content": MessageLookupByLibrary.simpleMessage("Nội dung"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage("Nội dung không được để trống"),
    "contentScheme": MessageLookupByLibrary.simpleMessage("Content"),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "Quản lý quy tắc đã thêm toàn cục",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Sao chép liên kết"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("Sao chép thành công"),
    "core": MessageLookupByLibrary.simpleMessage("Lõi"),
    "coreStatus": MessageLookupByLibrary.simpleMessage("Trạng thái lõi"),
    "country": MessageLookupByLibrary.simpleMessage("Quốc gia"),
    "crashTest": MessageLookupByLibrary.simpleMessage("Kiểm tra lỗi"),
    "crashlytics": MessageLookupByLibrary.simpleMessage("Phân tích lỗi"),
    "crashlyticsTip": MessageLookupByLibrary.simpleMessage(
      "Khi bật, tự động tải lên nhật ký lỗi khi ứng dụng bị lỗi",
    ),
    "create": MessageLookupByLibrary.simpleMessage("Tạo mới"),
    "createProfile": MessageLookupByLibrary.simpleMessage("Tạo cấu hình"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Thời gian tạo"),
    "custom": MessageLookupByLibrary.simpleMessage("Tuỳ chỉnh"),
    "dark": MessageLookupByLibrary.simpleMessage("Tối"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Bảng điều khiển"),
    "dataChangedSave": MessageLookupByLibrary.simpleMessage(
      "Phát hiện thay đổi dữ liệu, bạn có muốn lưu không?",
    ),
    "dataCollectionContent": MessageLookupByLibrary.simpleMessage(
      "Ứng dụng này sử dụng Firebase Crashlytics để thu thập thông tin lỗi nhằm cải thiện độ ổn định.\nDữ liệu thu thập bao gồm thông tin thiết bị và chi tiết lỗi, không bao gồm dữ liệu cá nhân nhạy cảm.",
    ),
    "dataCollectionTip": MessageLookupByLibrary.simpleMessage("Thông báo thu thập dữ liệu"),
    "daysAgo": m0,
    "defaultNameserver": MessageLookupByLibrary.simpleMessage("Máy chủ DNS mặc định"),
    "defaultNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Để phân giải máy chủ DNS",
    ),
    "defaultText": MessageLookupByLibrary.simpleMessage("Mặc định"),
    "delay": MessageLookupByLibrary.simpleMessage("Độ trễ"),
    "delayTest": MessageLookupByLibrary.simpleMessage("Kiểm tra độ trễ"),
    "delete": MessageLookupByLibrary.simpleMessage("Xóa"),
    "deleteMultipTip": m1,
    "deleteTip": m2,
    "desc": MessageLookupByLibrary.simpleMessage(
      "Ứng dụng proxy đa nền tảng dựa trên ClashMeta, đơn giản và dễ sử dụng, mã nguồn mở.",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("Đích đến"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage("GeoIP đích"),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage("IPASN đích"),
    "details": m3,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "Dựa vào API bên thứ ba chỉ mang tính tham khảo",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("Chế độ nhà phát triển"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "Chế độ nhà phát triển đã được bật.",
    ),
    "direct": MessageLookupByLibrary.simpleMessage("Trực tiếp"),
    "disableUDP": MessageLookupByLibrary.simpleMessage("Tắt UDP"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage("Phát hiện phiên bản mới"),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "Phần mềm này chỉ dùng cho mục đích phi thương mại như học tập, trao đổi và nghiên cứu khoa học.",
    ),
    "disclaimer": MessageLookupByLibrary.simpleMessage("Tuyên bố miễn trách"),
    "disconnected": MessageLookupByLibrary.simpleMessage("Chưa kết nối"),
    "dnsDesc": MessageLookupByLibrary.simpleMessage("Cập nhật cài đặt DNS"),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("Chiếm quyền DNS"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("Chế độ DNS"),
    "domain": MessageLookupByLibrary.simpleMessage("Tên miền"),
    "doYouWantToPass": MessageLookupByLibrary.simpleMessage("Bạn có muốn chuyển tiếp không"),
    "download": MessageLookupByLibrary.simpleMessage("Tải xuống"),
    "edit": MessageLookupByLibrary.simpleMessage("Chỉnh sửa"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage("Chỉnh sửa quy tắc toàn cục"),
    "editProxy": MessageLookupByLibrary.simpleMessage("Chỉnh sửa proxy"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("Chỉnh sửa nhóm proxy"),
    "editRule": MessageLookupByLibrary.simpleMessage("Chỉnh sửa quy tắc"),
    "editSsid": MessageLookupByLibrary.simpleMessage("Chỉnh sửa SSID"),
    "emptyTip": m4,
    "en": MessageLookupByLibrary.simpleMessage("Tiếng Anh"),
    "entries": MessageLookupByLibrary.simpleMessage(" mục"),
    "excludeProxyFilter": MessageLookupByLibrary.simpleMessage("Loại trừ bộ lọc proxy"),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("Loại trừ SSID"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "Khi kết nối Wi-Fi SSID bị loại trừ, trạng thái ứng dụng sẽ tự động chuyển đổi.",
    ),
    "excludeType": MessageLookupByLibrary.simpleMessage("Loại trừ kiểu"),
    "exclude": MessageLookupByLibrary.simpleMessage("Ẩn khỏi tác vụ gần đây"),
    "excludeDesc": MessageLookupByLibrary.simpleMessage(
      "Khi ứng dụng ở nền, ứng dụng bị ẩn khỏi tác vụ gần đây",
    ),
    "existsTip": m5,
    "exit": MessageLookupByLibrary.simpleMessage("Thoát"),
    "expand": MessageLookupByLibrary.simpleMessage("Chuẩn"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("Trạng thái mong đợi"),
    "externalController": MessageLookupByLibrary.simpleMessage("Bộ điều khiển ngoài"),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "Khi bật, lõi Clash có thể được điều khiển qua cổng 9090",
    ),
    "externalFetch": MessageLookupByLibrary.simpleMessage("Tải ngoài"),
    "externalLink": MessageLookupByLibrary.simpleMessage("Liên kết ngoài"),
    "exportFile": MessageLookupByLibrary.simpleMessage("Xuất file"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Xuất nhật ký"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Xuất thành công"),
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Bộ lọc Fakeip"),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Phạm vi Fakeip"),
    "fallback": MessageLookupByLibrary.simpleMessage("Dự phòng"),
    "fallbackDesc": MessageLookupByLibrary.simpleMessage("Thường dùng DNS nước ngoài"),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("Bộ lọc dự phòng"),
    "fidelityScheme": MessageLookupByLibrary.simpleMessage("Fidelity"),
    "file": MessageLookupByLibrary.simpleMessage("File"),
    "fileDesc": MessageLookupByLibrary.simpleMessage("Tải lên trực tiếp cấu hình"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "File đã được sửa đổi. Bạn có muốn lưu thay đổi không?",
    ),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("Tìm tiến trình"),
    "findProcessModeDesc": MessageLookupByLibrary.simpleMessage(
      "Có một số hao tổn hiệu suất khi bật",
    ),
    "fontFamily": MessageLookupByLibrary.simpleMessage("Phông chữ"),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn buộc khởi động lại lõi không?",
    ),
    "fruitSaladScheme": MessageLookupByLibrary.simpleMessage("FruitSalad"),
    "general": MessageLookupByLibrary.simpleMessage("Chung"),
    "geodataLoader": MessageLookupByLibrary.simpleMessage("Chế độ bộ nhớ thấp Geo"),
    "geodataLoaderDesc": MessageLookupByLibrary.simpleMessage(
      "Bật sẽ dùng bộ tải Geo tiêu thụ ít bộ nhớ",
    ),
    "geoipCode": MessageLookupByLibrary.simpleMessage("Mã Geoip"),
    "global": MessageLookupByLibrary.simpleMessage("Toàn cục"),
    "go": MessageLookupByLibrary.simpleMessage("Đi"),
    "goDownload": MessageLookupByLibrary.simpleMessage("Tải xuống"),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage("Đi đến cấu hình script"),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage(
      "Bạn có muốn lưu tạm thay đổi không?",
    ),
    "hideFromList": MessageLookupByLibrary.simpleMessage("Ẩn khỏi danh sách"),
    "host": MessageLookupByLibrary.simpleMessage("Máy chủ"),
    "hostsDesc": MessageLookupByLibrary.simpleMessage("Thêm Hosts"),
    "hotkeyConflict": MessageLookupByLibrary.simpleMessage("Xung đột phím tắt"),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage("Quản lý phím tắt"),
    "hotkeyManagementDesc": MessageLookupByLibrary.simpleMessage(
      "Dùng bàn phím để điều khiển ứng dụng",
    ),
    "hoursAgo": m6,
    "icon": MessageLookupByLibrary.simpleMessage("Biểu tượng"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("Bản ghi biểu tượng"),
    "iconStyle": MessageLookupByLibrary.simpleMessage("Kiểu biểu tượng"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("URL biểu tượng"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Bỏ qua tối ưu hoá pin",
    ),
    "import": MessageLookupByLibrary.simpleMessage("Nhập"),
    "importFile": MessageLookupByLibrary.simpleMessage("Nhập từ file"),
    "importFromURL": MessageLookupByLibrary.simpleMessage("Nhập từ URL"),
    "importUrl": MessageLookupByLibrary.simpleMessage("Nhập từ URL"),
    "includeAllProxies": MessageLookupByLibrary.simpleMessage("Bao gồm tất cả proxy"),
    "includeAllProxiesTip": MessageLookupByLibrary.simpleMessage(
      "Nhập tất cả proxy không chứa nhóm proxy, có thể thêm nhóm proxy bổ sung bên dưới",
    ),
    "includeAllProxyProviders": MessageLookupByLibrary.simpleMessage(
      "Bao gồm tất cả nguồn proxy",
    ),
    "includeAllProxyProvidersTip": MessageLookupByLibrary.simpleMessage(
      "Khi bật, sẽ ghi đè các nguồn proxy đã nhập",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("Hiệu lực lâu dài"),
    "init": MessageLookupByLibrary.simpleMessage("Khởi tạo"),
    "inputCorrectHotkey": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập phím tắt đúng",
    ),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage("Nhập tên nhóm proxy"),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage("Nhập nội dung quy tắc"),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage("Chọn thông minh"),
    "internet": MessageLookupByLibrary.simpleMessage("Internet"),
    "interval": MessageLookupByLibrary.simpleMessage("Khoảng thời gian"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("Địa chỉ IP nội bộ"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage("File sao lưu không hợp lệ"),
    "invalidPolicy": m7,
    "invalidProxy": m8,
    "invalidProxyProvider": m9,
    "invalidSubRule": m10,
    "ipcidr": MessageLookupByLibrary.simpleMessage("Ipcidr"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage("Khi bật sẽ nhận được lưu lượng IPv6"),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage("Cho phép IPv6 đầu vào"),
    "ja": MessageLookupByLibrary.simpleMessage("Tiếng Nhật"),
    "justNow": MessageLookupByLibrary.simpleMessage("Vừa xong"),
    "key": MessageLookupByLibrary.simpleMessage("Khoá"),
    "language": MessageLookupByLibrary.simpleMessage("Ngôn ngữ"),
    "layout": MessageLookupByLibrary.simpleMessage("Bố cục"),
    "light": MessageLookupByLibrary.simpleMessage("Sáng"),
    "list": MessageLookupByLibrary.simpleMessage("Danh sách"),
    "listen": MessageLookupByLibrary.simpleMessage("Lắng nghe"),
    "loading": MessageLookupByLibrary.simpleMessage("Đang tải..."),
    "loadTest": MessageLookupByLibrary.simpleMessage("Kiểm tra tải"),
    "local": MessageLookupByLibrary.simpleMessage("Cục bộ"),
    "localBackupDesc": MessageLookupByLibrary.simpleMessage("Sao lưu dữ liệu cục bộ"),
    "locationPermission": MessageLookupByLibrary.simpleMessage("Quyền vị trí"),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Theo yêu cầu hệ thống, cần cấp quyền vị trí để lấy tên Wi-Fi.",
    ),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "Quyền vị trí bị từ chối, không thể lấy tên Wi-Fi. Vui lòng mở quyền vị trí thủ công trong cài đặt hệ thống.",
    ),
    "locationPermissionGuide": m11,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Cần quyền vị trí",
    ),
    "log": MessageLookupByLibrary.simpleMessage("Nhật ký"),
    "logLevel": MessageLookupByLibrary.simpleMessage("Cấp độ nhật ký"),
    "logcat": MessageLookupByLibrary.simpleMessage("Logcat"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage("Tắt sẽ ẩn mục nhật ký"),
    "logs": MessageLookupByLibrary.simpleMessage("Nhật ký"),
    "logsDesc": MessageLookupByLibrary.simpleMessage("Ghi lại nhật ký"),
    "logsTest": MessageLookupByLibrary.simpleMessage("Kiểm tra nhật ký"),
    "loopback": MessageLookupByLibrary.simpleMessage("Công cụ mở khoá loopback"),
    "loopbackDesc": MessageLookupByLibrary.simpleMessage("Dùng để mở khoá UWP loopback"),
    "loose": MessageLookupByLibrary.simpleMessage("Rộng"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("Khớp IP nguồn"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("Số lần thất bại tối đa"),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("Thông tin bộ nhớ"),
    "messageTest": MessageLookupByLibrary.simpleMessage("Kiểm tra thông báo"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage("Đây là một thông báo."),
    "min": MessageLookupByLibrary.simpleMessage("Thu nhỏ"),
    "minutesAgo": m12,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Cổng hỗn hợp"),
    "mode": MessageLookupByLibrary.simpleMessage("Chế độ"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("Đơn sắc"),
    "monthsAgo": m13,
    "more": MessageLookupByLibrary.simpleMessage("Thêm"),
    "name": MessageLookupByLibrary.simpleMessage("Tên"),
    "nameserver": MessageLookupByLibrary.simpleMessage("Máy chủ tên"),
    "nameserverDesc": MessageLookupByLibrary.simpleMessage("Để phân giải tên miền"),
    "nameserverPolicy": MessageLookupByLibrary.simpleMessage("Chính sách máy chủ tên"),
    "nameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "Chỉ định chính sách máy chủ tên tương ứng",
    ),
    "network": MessageLookupByLibrary.simpleMessage("Mạng"),
    "networkDesc": MessageLookupByLibrary.simpleMessage(
      "Thay đổi cài đặt liên quan đến mạng",
    ),
    "networkDetection": MessageLookupByLibrary.simpleMessage("Kiểm tra mạng"),
    "networkException": MessageLookupByLibrary.simpleMessage(
      "Ngoại lệ mạng, vui lòng kiểm tra kết nối và thử lại",
    ),
    "networkSpeed": MessageLookupByLibrary.simpleMessage("Tốc độ mạng"),
    "networkType": MessageLookupByLibrary.simpleMessage("Loại mạng"),
    "neutralScheme": MessageLookupByLibrary.simpleMessage("Trung tính"),
    "noData": MessageLookupByLibrary.simpleMessage("Không có dữ liệu"),
    "noHotKey": MessageLookupByLibrary.simpleMessage("Không có phím tắt"),
    "noInfo": MessageLookupByLibrary.simpleMessage("Không có thông tin"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage("Không nhắc lại"),
    "noNetwork": MessageLookupByLibrary.simpleMessage("Không có mạng"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("Ứng dụng không có mạng"),
    "noRecords": MessageLookupByLibrary.simpleMessage("Không có bản ghi"),
    "noResolve": MessageLookupByLibrary.simpleMessage("Không phân giải IP"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage("Không phân giải hostname"),
    "none": MessageLookupByLibrary.simpleMessage("Không"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "Nhóm proxy hiện tại không thể chọn.",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Chưa có cấu hình, vui lòng thêm cấu hình",
    ),
    "nullTip": m14,
    "numberTip": m15,
    "onDemand": MessageLookupByLibrary.simpleMessage("Theo yêu cầu"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "Cấu hình trạng thái chương trình cho các tình huống cụ thể",
    ),
    "onlyIcon": MessageLookupByLibrary.simpleMessage("Biểu tượng"),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage("Chỉ thống kê proxy"),
    "onlyStatisticsProxyDesc": MessageLookupByLibrary.simpleMessage(
      "Khi bật, chỉ thống kê lưu lượng proxy",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("Tuỳ chọn"),
    "options": MessageLookupByLibrary.simpleMessage("Tuỳ chọn"),
    "other": MessageLookupByLibrary.simpleMessage("Khác"),
    "otherContributors": MessageLookupByLibrary.simpleMessage("Người đóng góp khác"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("Chế độ kết nối"),
    "overrideDns": MessageLookupByLibrary.simpleMessage("Ghi đè DNS"),
    "overrideDnsDesc": MessageLookupByLibrary.simpleMessage(
      "Bật sẽ ghi đè tuỳ chọn DNS trong cấu hình",
    ),
    "overrideMode": MessageLookupByLibrary.simpleMessage("Chế độ ghi đè"),
    "overrideScript": MessageLookupByLibrary.simpleMessage("Script ghi đè"),
    "overwriteTypeCustom": MessageLookupByLibrary.simpleMessage("Tuỳ chỉnh"),
    "overwriteTypeCustomDesc": MessageLookupByLibrary.simpleMessage(
      "Chế độ tuỳ chỉnh, tuỳ chỉnh hoàn toàn nhóm proxy và quy tắc",
    ),
    "override": MessageLookupByLibrary.simpleMessage("Ghi đè"),
    "palette": MessageLookupByLibrary.simpleMessage("Bảng màu"),
    "password": MessageLookupByLibrary.simpleMessage("Mật khẩu"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage("Vui lòng liên kết WebDAV"),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập tên script",
    ),
    "pleaseInputAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập mật khẩu quản trị viên",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "Vui lòng tải lên mã QR hợp lệ",
    ),
    "portConflictTip": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập cổng khác",
    ),
    "portTip": m16,
    "port": MessageLookupByLibrary.simpleMessage("Cổng"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("Điều kiện tiên quyết"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage("Vui lòng nhấn bàn phím."),
    "preview": MessageLookupByLibrary.simpleMessage("Xem trước"),
    "process": MessageLookupByLibrary.simpleMessage("Tiến trình"),
    "profile": MessageLookupByLibrary.simpleMessage("Cấu hình"),
    "profileAutoUpdateIntervalInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập định dạng thời gian hợp lệ",
    ),
    "profileAutoUpdateIntervalNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập thời gian cập nhật tự động",
    ),
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "Cấu hình đã được sửa đổi. Bạn có muốn tắt tự động cập nhật không?",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập tên cấu hình",
    ),
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập URL hợp lệ",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập URL cấu hình",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("Cấu hình"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("Sắp xếp cấu hình"),
    "project": MessageLookupByLibrary.simpleMessage("Dự án"),
    "proxyChains": MessageLookupByLibrary.simpleMessage("Chuỗi proxy"),
    "proxyDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "Phát hiện proxy đã chọn bất thường",
    ),
    "proxyFilter": MessageLookupByLibrary.simpleMessage("Lọc proxy"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("Nhóm proxy"),
    "proxyGroupDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "Phát hiện nhóm proxy hiện tại bất thường",
    ),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage("Nhóm proxy trống"),
    "proxyGroupNameDuplicate": MessageLookupByLibrary.simpleMessage(
      "Tên nhóm proxy bị trùng",
    ),
    "proxyGroupNameEmpty": MessageLookupByLibrary.simpleMessage(
      "Tên nhóm proxy không được để trống",
    ),
    "proxyNameserver": MessageLookupByLibrary.simpleMessage("Máy chủ tên proxy"),
    "proxyNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Tên miền để phân giải các node proxy",
    ),
    "proxyPort": MessageLookupByLibrary.simpleMessage("Cổng Proxy"),
    "proxyProviderDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "Phát hiện nguồn proxy đã chọn bất thường",
    ),
    "proxyProviders": MessageLookupByLibrary.simpleMessage("Nguồn proxy"),
    "proxyProvidersEmpty": MessageLookupByLibrary.simpleMessage("Nguồn proxy trống"),
    "proxyProvidersNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Nguồn proxy không được để trống",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("Loại proxy"),
    "proxies": MessageLookupByLibrary.simpleMessage("Proxy"),
    "proxiesEmpty": MessageLookupByLibrary.simpleMessage("Proxy trống"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("Xoá bộ nhớ đệm"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("Chế độ đen thuần"),
    "qrcode": MessageLookupByLibrary.simpleMessage("Mã QR"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage("Quét mã QR để lấy cấu hình"),
    "quickFill": MessageLookupByLibrary.simpleMessage("Điền nhanh"),
    "rainbowScheme": MessageLookupByLibrary.simpleMessage("Rainbow"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Cổng Redir"),
    "redo": MessageLookupByLibrary.simpleMessage("Làm lại"),
    "remote": MessageLookupByLibrary.simpleMessage("Từ xa"),
    "remoteBackupDesc": MessageLookupByLibrary.simpleMessage(
      "Sao lưu dữ liệu cục bộ lên WebDAV",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Xoá"),
    "rename": MessageLookupByLibrary.simpleMessage("Đổi tên"),
    "request": MessageLookupByLibrary.simpleMessage("Yêu cầu"),
    "requests": MessageLookupByLibrary.simpleMessage("Yêu cầu"),
    "requestsDesc": MessageLookupByLibrary.simpleMessage("Xem các yêu cầu gần đây"),
    "reset": MessageLookupByLibrary.simpleMessage("Đặt lại"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "Trang hiện tại có thay đổi. Bạn có chắc muốn đặt lại không?",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage("Xác nhận đặt lại"),
    "respectRules": MessageLookupByLibrary.simpleMessage("Tuân theo quy tắc"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "Kết nối DNS theo quy tắc, cần cấu hình proxy-server-nameserver",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("Tài nguyên"),
    "resourcesDesc": MessageLookupByLibrary.simpleMessage(
      "Thông tin liên quan đến tài nguyên ngoài",
    ),
    "restart": MessageLookupByLibrary.simpleMessage("Khởi động lại"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Bạn có chắc muốn khởi động lại lõi không?",
    ),
    "restore": MessageLookupByLibrary.simpleMessage("Khôi phục"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("Khôi phục tất cả dữ liệu"),
    "restoreException": MessageLookupByLibrary.simpleMessage("Ngoại lệ khôi phục"),
    "restoreFromFileDesc": MessageLookupByLibrary.simpleMessage("Khôi phục dữ liệu qua file"),
    "restoreFromWebDAVDesc": MessageLookupByLibrary.simpleMessage(
      "Khôi phục dữ liệu qua WebDAV",
    ),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage(
      "Chỉ khôi phục file cấu hình",
    ),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("Chiến lược khôi phục"),
    "restoreStrategy_compatible": MessageLookupByLibrary.simpleMessage("Tương thích"),
    "restoreStrategy_override": MessageLookupByLibrary.simpleMessage("Ghi đè"),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage("Khôi phục thành công"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("Địa chỉ định tuyến"),
    "routeAddressDesc": MessageLookupByLibrary.simpleMessage(
      "Cấu hình địa chỉ định tuyến lắng nghe",
    ),
    "routeMode": MessageLookupByLibrary.simpleMessage("Chế độ định tuyến"),
    "routeMode_bypassPrivate": MessageLookupByLibrary.simpleMessage(
      "Bỏ qua địa chỉ định tuyến riêng tư",
    ),
    "routeMode_config": MessageLookupByLibrary.simpleMessage("Dùng cấu hình"),
    "ru": MessageLookupByLibrary.simpleMessage("Tiếng Nga"),
    "rule": MessageLookupByLibrary.simpleMessage("Quy tắc"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage("Quy tắc logic VÀ"),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage("Khớp tên miền đầy đủ"),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp từ khoá tên miền",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp ký tự đại diện, chỉ hỗ trợ * và ?",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp hậu tố tên miền",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp nhãn DSCP (chỉ tproxy udp inbound)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp phạm vi cổng đích yêu cầu",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp mã quốc gia của IP",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp tên miền trong Geosite",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage("Khớp tên đầu vào"),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage("Khớp cổng đầu vào"),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage("Khớp loại đầu vào"),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp tên người dùng đầu vào, hỗ trợ nhiều tên phân cách bằng /",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage("Khớp ASN của IP"),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "Khớp phạm vi địa chỉ IP, IP-CIDR6 chỉ là bí danh",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage("Khớp phạm vi địa chỉ IP"),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp phạm vi hậu tố IP",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp tất cả yêu cầu, không cần điều kiện",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage("Khớp TCP hoặc UDP"),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage("Quy tắc logic KHÔNG"),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("Quy tắc logic HOẶC"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp theo tên tiến trình, khớp tên gói trên Android",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp theo regex tên tiến trình",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp theo đường dẫn tiến trình đầy đủ",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp theo regex đường dẫn tiến trình",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "Tham chiếu bộ quy tắc, cần cấu hình rule-providers",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp mã quốc gia của IP nguồn",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp ASN của IP nguồn",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp phạm vi địa chỉ IP nguồn",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp phạm vi hậu tố IP nguồn",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp phạm vi cổng nguồn yêu cầu",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "Khớp với quy tắc phụ, chú ý dùng dấu ngoặc đơn",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage("Khớp Linux USER ID"),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("Quy tắc trống"),
    "ruleName": MessageLookupByLibrary.simpleMessage("Tên quy tắc"),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("Nguồn quy tắc"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("Bộ quy tắc"),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("Đích quy tắc"),
    "save": MessageLookupByLibrary.simpleMessage("Lưu"),
    "saveChanges": MessageLookupByLibrary.simpleMessage(
      "Bạn có muốn lưu thay đổi không?",
    ),
    "script": MessageLookupByLibrary.simpleMessage("Script"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "Chế độ script, dùng script mở rộng ngoài, cung cấp khả năng ghi đè cấu hình một cú nhấp",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Tìm kiếm"),
    "seconds": MessageLookupByLibrary.simpleMessage("Giây"),
    "select": MessageLookupByLibrary.simpleMessage("Chọn"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Chọn tất cả"),
    "selectProxies": MessageLookupByLibrary.simpleMessage("Chọn proxy"),
    "selectProxyProviders": MessageLookupByLibrary.simpleMessage("Chọn nguồn proxy"),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage("Vui lòng chọn bộ quy tắc"),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "Vui lòng chọn chiến lược phân tách",
    ),
    "selectSubRule": MessageLookupByLibrary.simpleMessage("Vui lòng chọn quy tắc phụ"),
    "selected": MessageLookupByLibrary.simpleMessage("Đã chọn"),
    "selectedCountTitle": m17,
    "settings": MessageLookupByLibrary.simpleMessage("Cài đặt"),
    "show": MessageLookupByLibrary.simpleMessage("Hiển thị"),
    "shrink": MessageLookupByLibrary.simpleMessage("Thu nhỏ"),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("Khởi động im lặng"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage("Khởi động ở nền"),
    "size": MessageLookupByLibrary.simpleMessage("Kích thước"),
    "socksPort": MessageLookupByLibrary.simpleMessage("Cổng Socks"),
    "sort": MessageLookupByLibrary.simpleMessage("Sắp xếp"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("IP nguồn"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("Proxy đặc biệt"),
    "specialRules": MessageLookupByLibrary.simpleMessage("quy tắc đặc biệt"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("Thống kê tốc độ"),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("Chiến lược phân tách"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Chiến lược phân tách không được để trống",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("Danh sách SSID trống"),
    "stackMode": MessageLookupByLibrary.simpleMessage("Chế độ ngăn xếp"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "Chế độ chuẩn, ghi đè cấu hình cơ bản, cung cấp khả năng thêm quy tắc đơn giản",
    ),
    "standard": MessageLookupByLibrary.simpleMessage("Chuẩn"),
    "start": MessageLookupByLibrary.simpleMessage("Bắt đầu"),
    "startVpn": MessageLookupByLibrary.simpleMessage("Đang bật VPN..."),
    "status": MessageLookupByLibrary.simpleMessage("Trạng thái"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "DNS hệ thống sẽ được dùng khi tắt",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("Dừng"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("Đang tắt VPN..."),
    "style": MessageLookupByLibrary.simpleMessage("Kiểu"),
    "subRule": MessageLookupByLibrary.simpleMessage("Quy tắc phụ"),
    "subRuleEmpty": MessageLookupByLibrary.simpleMessage("Quy tắc phụ trống"),
    "subRuleNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Quy tắc phụ không được để trống",
    ),
    "submit": MessageLookupByLibrary.simpleMessage("Gửi"),
    "suspended": MessageLookupByLibrary.simpleMessage("Đã tạm dừng..."),
    "sync": MessageLookupByLibrary.simpleMessage("Đồng bộ"),
    "system": MessageLookupByLibrary.simpleMessage("Hệ thống"),
    "systemApp": MessageLookupByLibrary.simpleMessage("Ứng dụng hệ thống"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("Proxy hệ thống"),
    "systemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "Đính kèm HTTP proxy vào VpnService",
    ),
    "tab": MessageLookupByLibrary.simpleMessage("Tab"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("Hiệu ứng tab"),
    "tabAnimationDesc": MessageLookupByLibrary.simpleMessage(
      "Chỉ có hiệu lực trên giao diện di động",
    ),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("Nhấn để uỷ quyền"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP đồng thời"),
    "tcpConcurrentDesc": MessageLookupByLibrary.simpleMessage(
      "Bật sẽ cho phép TCP chạy đồng thời",
    ),
    "testInterval": MessageLookupByLibrary.simpleMessage("Khoảng thời gian kiểm tra"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("Kiểm tra khi dùng"),
    "testUrl": MessageLookupByLibrary.simpleMessage("URL kiểm tra"),
    "textScale": MessageLookupByLibrary.simpleMessage("Tỷ lệ chữ"),
    "theme": MessageLookupByLibrary.simpleMessage("Giao diện"),
    "themeColor": MessageLookupByLibrary.simpleMessage("Màu giao diện"),
    "themeDesc": MessageLookupByLibrary.simpleMessage(
      "Chỉnh chế độ tối, điều chỉnh màu sắc",
    ),
    "themeMode": MessageLookupByLibrary.simpleMessage("Chế độ giao diện"),
    "tight": MessageLookupByLibrary.simpleMessage("Chặt"),
    "time": MessageLookupByLibrary.simpleMessage("Thời gian"),
    "timeout": MessageLookupByLibrary.simpleMessage("Thời gian chờ"),
    "tip": MessageLookupByLibrary.simpleMessage("Gợi ý"),
    "toggle": MessageLookupByLibrary.simpleMessage("Bật/tắt"),
    "tonalSpotScheme": MessageLookupByLibrary.simpleMessage("TonalSpot"),
    "tools": MessageLookupByLibrary.simpleMessage("Công cụ"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Cổng Tproxy"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("Lưu lượng sử dụng"),
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunDesc": MessageLookupByLibrary.simpleMessage(
      "Chỉ có hiệu lực ở chế độ quản trị viên",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("Tắt"),
    "turnOn": MessageLookupByLibrary.simpleMessage("Bật"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("Độ trễ thống nhất"),
    "unifiedDelayDesc": MessageLookupByLibrary.simpleMessage(
      "Loại bỏ độ trễ thêm như bắt tay",
    ),
    "undo": MessageLookupByLibrary.simpleMessage("Hoàn tác"),
    "unknown": MessageLookupByLibrary.simpleMessage("Không xác định"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage(
      "Lỗi mạng không xác định",
    ),
    "unnamed": MessageLookupByLibrary.simpleMessage("Chưa đặt tên"),
    "update": MessageLookupByLibrary.simpleMessage("Cập nhật"),
    "upload": MessageLookupByLibrary.simpleMessage("Tải lên"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlDesc": MessageLookupByLibrary.simpleMessage("Lấy cấu hình qua URL"),
    "urlTip": m18,
    "useHosts": MessageLookupByLibrary.simpleMessage("Dùng hosts"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("Dùng hosts hệ thống"),
    "value": MessageLookupByLibrary.simpleMessage("Giá trị"),
    "vibrantScheme": MessageLookupByLibrary.simpleMessage("Rực rỡ"),
    "vi": MessageLookupByLibrary.simpleMessage("Tiếng Việt"),
    "view": MessageLookupByLibrary.simpleMessage("Xem"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "Phát hiện thay đổi cấu hình VPN",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "Tự động định tuyến toàn bộ lưu lượng hệ thống qua VpnService",
    ),
    "vpnTip": MessageLookupByLibrary.simpleMessage(
      "Thay đổi có hiệu lực sau khi khởi động lại VPN",
    ),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage("Cấu hình WebDAV"),
    "yearsAgo": m19,
    "zh_CN": MessageLookupByLibrary.simpleMessage("Tiếng Trung (Giản thể)"),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Chưa có cấu hình, vui lòng thêm cấu hình",
    ),
    "networkException": MessageLookupByLibrary.simpleMessage(
      "Ngoại lệ mạng, vui lòng kiểm tra kết nối và thử lại",
    ),
    "addedRules": MessageLookupByLibrary.simpleMessage("Quy tắc đã thêm"),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "Để đảm bảo hoạt động nền, vui lòng tắt tối ưu hoá pin cho ứng dụng này. Nhấn để vào cài đặt.",
    ),
    "noData": MessageLookupByLibrary.simpleMessage("Không có dữ liệu"),
  };
}
