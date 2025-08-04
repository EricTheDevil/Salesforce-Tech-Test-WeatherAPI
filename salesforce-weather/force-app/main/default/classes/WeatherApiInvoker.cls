/**
 * Invokes WeatherAPI for current conditions.
 */
public with sharing class WeatherApiInvoker {

    private static final Integer STATUS_OK = 200;
    private static final Integer STATUS_BAD_REQUEST = 400;
    private static final Integer STATUS_INTERNAL_ERROR = 500;
    private static final Integer STATUS_SERVICE_UNAVAILABLE = 503;
    private static final Integer TIMEOUT_MS = 10000;

    public class Request {
        @InvocableVariable(required=true)
        public String city;
    }

    public class Response {
        @InvocableVariable public Integer statusCode;
        @InvocableVariable public String conditionText;
        @InvocableVariable public String iconUrl;
        @InvocableVariable public Decimal tempC;
        @InvocableVariable public Long lastUpdatedEpoch;
        @InvocableVariable public String rawJson;
    }

    /**
     * Calls WeatherAPI current.json and returns typed fields.
     */
    @InvocableMethod(label='WeatherAPI: Get Current' description='Calls WeatherAPI current.json and returns typed fields')
    public static List<Response> invoke(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return new List<Response>();
        }

        WeatherAPI_Config__mdt cfg = [
            SELECT API_Key__c, Base_Path__c
            FROM WeatherAPI_Config__mdt
            WHERE DeveloperName = 'Default'
            LIMIT 1
        ];

        List<Response> out = new List<Response>();

        for (Request req : requests) {
            Response r = new Response();

            if (cfg == null || String.isBlank(cfg.API_Key__c)) {
                r.statusCode = STATUS_SERVICE_UNAVAILABLE;
                r.rawJson = 'Config missing or API key blank';
                out.add(r);
                continue;
            }
            if (req == null || String.isBlank(req.city)) {
                r.statusCode = STATUS_BAD_REQUEST;
                r.rawJson = 'City is required';
                out.add(r);
                continue;
            }

            String basePath = String.isBlank(cfg.Base_Path__c) ? '/v1/current.json' : cfg.Base_Path__c;
            String endpoint = 'callout:WeatherAPI' + basePath +
                              '?q=' + EncodingUtil.urlEncode(req.city, 'UTF-8') +
                              '&aqi=no' +
                              '&key=' + EncodingUtil.urlEncode(cfg.API_Key__c, 'UTF-8');

            HttpRequest hr = new HttpRequest();
            hr.setMethod('GET');
            hr.setEndpoint(endpoint);
            hr.setTimeout(TIMEOUT_MS);

            Http http = new Http();
            HttpResponse resp;
            try {
                resp = http.send(hr);
                r.statusCode = resp.getStatusCode();
                r.rawJson = resp.getBody();
            } catch (Exception ex) {
                r.statusCode = STATUS_INTERNAL_ERROR;
                r.rawJson = 'Callout failed: ' + ex.getMessage();
                out.add(r);
                continue;
            }

            if (r.statusCode == STATUS_OK && String.isNotBlank(r.rawJson)) {
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(r.rawJson);
                Map<String, Object> current = (Map<String, Object>) root.get('current');
                if (current != null) {
                    Object tempC = current.get('temp_c');
                    if (tempC != null) r.tempC = Decimal.valueOf(String.valueOf(tempC));
                    Object lastUpd = current.get('last_updated_epoch');
                    if (lastUpd != null) r.lastUpdatedEpoch = Long.valueOf(String.valueOf(lastUpd));
                    Map<String, Object> cond = (Map<String, Object>) current.get('condition');
                    if (cond != null) {
                        Object text = cond.get('text');
                        if (text != null) r.conditionText = String.valueOf(text);
                        Object icon = cond.get('icon');
                        if (icon != null) {
                            String url = String.valueOf(icon);
                            if (url.startsWith('//')) url = 'https:' + url;
                            r.iconUrl = url;
                        }
                    }
                }
            }

            out.add(r);
        }

        return out;
    }
}