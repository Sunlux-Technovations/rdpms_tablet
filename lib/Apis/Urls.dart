final baseUrl = 'http://192.109.209.35:3004/api';
// final baseUrl='http://54.148.97.150:3004/api';
final loginUrl = "$baseUrl/users/findUserAndVerify";
final setUpPassword = "$baseUrl/users/changePassword";
final getAlertSummaryForDevice = "$baseUrl/alert/getAlertSummaryForDevice";
final getSensorValueByGroup = "$baseUrl/devices/getSensorValueByGroup";
final getStationValues = "$baseUrl/devices/getStation";
final getAlertsCharts = "$baseUrl/alert/getAlertsForCharts";
// const updateAlert = "http://192.109.209.80:3004/alert/updateAlert";
final getSensorValuesByStation =
    "$baseUrl/devices/getSensorValueByGroupStation";
final getAlaramReport = "$baseUrl/reports/getAlarmReport";
final getAlertCountForDashboard = "$baseUrl/alert/getResponseAlertCount";
final getAllAlertsMaintenance = "$baseUrl/devices/getAllAlertsMaintenance";
final getMaintenanceByStationDetails =
    "$baseUrl/maintenance/getMaintenanceDetailsBasedOnStation";
final getMaintenanceMainGo = "$baseUrl/maintenance/getMaintenanceMainGo";
final showDeletedHistory = "$baseUrl/maintenance/getMaintenanceHistoryDeleted";
final deleteMaintenanceHistory =
    "$baseUrl/maintenance/updateDeleteMaintenanceHistory";
final getUpdateLogs = "$baseUrl/maintenance/updateMaintenanceLogs";
final getTags = "$baseUrl/maintenance/getTechnicianTags";
final getAlertsNotification = "$baseUrl/alert/getAlerts";
final getUpdateAlert = "$baseUrl/alert/updateAlert";
final getAlertsDashboard = "$baseUrl/alert/getAlertByStationAssetsCount";
final getAnalyticsData = "$baseUrl/devices/getAllAnalytics";
final getAlerts = "$baseUrl/alert/getAlerts";
final getAckUpdates = "$baseUrl/alert/updateAlert";
final getAckAlerts = "$baseUrl/alert/updateAckForAlert";
final getAlertHistory = "$baseUrl/alert/getAlertByAllForHistory";
final alertDashboard = "$baseUrl/alert/getAlertByStationAssetsCount";
final totalAlertsByStation = "$baseUrl/alert/getLocationAlertCount";
final showAckAlert = "$baseUrl/alert/getAckAlerts";
final assetpagessocket="http://54.148.97.150:3004/sensors";
final dashboardpagesocket="http://192.109.209.35:3004/alerts";