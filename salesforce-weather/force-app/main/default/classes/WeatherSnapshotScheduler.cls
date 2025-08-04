/**
 * Scheduler to kick off hourly weather batch refresh.
 */
public with sharing class WeatherSnapshotScheduler implements Schedulable {
    private static final Integer BATCH_SCOPE = 50;
    private static final String HOURLY_CRON = '0 0 * * * ?';

    /**
     * Runs the hourly batch job.
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new WeatherSnapshotBatch(), BATCH_SCOPE);
    }

    /**
     * Schedules the hourly batch.
     */
    public static Id scheduleHourly() {
        String cron = HOURLY_CRON;
        return System.schedule('Weather Snapshot Hourly', cron, new WeatherSnapshotScheduler());
    }
}