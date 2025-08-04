@IsTest
private class WeatherApiInvokerTest {
    @IsTest static void testInvokeSuccess() {
        String body = '{"current":{"temp_c":10,"last_updated_epoch":1691000000,"condition":{"text":"Cloudy","icon":"//icon"}}}';
        Test.setMock(HttpCalloutMock.class, new WeatherApiMock(200, body));
        WeatherApiInvoker.Request r = new WeatherApiInvoker.Request();
        r.city = 'London';
        List<WeatherApiInvoker.Response> resps = WeatherApiInvoker.invoke(new List<WeatherApiInvoker.Request>{ r });
        System.assertEquals(1, resps.size());
        System.assertEquals(200, resps[0].statusCode);
        System.assertEquals(10, resps[0].tempC);
    }
}