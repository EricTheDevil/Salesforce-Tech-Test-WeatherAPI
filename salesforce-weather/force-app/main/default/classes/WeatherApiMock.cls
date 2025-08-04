/**
 * Simple HTTP mock used in unit tests.
 */
@IsTest
public class WeatherApiMock implements HttpCalloutMock {
    private Integer code;
    private String body;
    public WeatherApiMock(Integer code, String body) {
        this.code = code;
        this.body = body;
    }
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(code);
        res.setBody(body);
        return res;
    }
}