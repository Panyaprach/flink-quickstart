package org.example;

import org.apache.flink.configuration.Configuration;
import org.apache.flink.metrics.Counter;
import org.apache.flink.metrics.Histogram;
import org.apache.flink.runtime.metrics.DescriptiveStatisticsHistogram;
import org.apache.flink.streaming.api.functions.windowing.ProcessAllWindowFunction;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;
import org.apache.flink.streaming.connectors.wikiedits.WikipediaEditEvent;
import org.apache.flink.util.Collector;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;
import java.util.Iterator;

public class UserLagProcessor extends ProcessAllWindowFunction<WikipediaEditEvent, String, TimeWindow> {
    private transient Counter eventCounter;
    private transient Histogram valueHistogram;

    private static Logger log = LoggerFactory.getLogger(UserLagProcessor.class);

    @Override
    public void open(Configuration parameters) throws Exception {
        super.open(parameters);

        eventCounter = getRuntimeContext()
                .getMetricGroup()
                .counter("events");

        valueHistogram = getRuntimeContext()
                .getMetricGroup()
                .histogram("value_histogram", new DescriptiveStatisticsHistogram(10_000));
    }

    @Override
    public void process(Context context, Iterable<WikipediaEditEvent> elements, Collector<String> out) throws Exception {
        TimeWindow window = context.window();
        long start = window.getStart();
        long end = window.getEnd();
        long current = System.currentTimeMillis();
        Iterator<WikipediaEditEvent> iterator = elements.iterator();
        log.info("Current thread {} Now {} processing Window from {} to {}", Thread.currentThread().getId(), new Date(current), new Date(start), new Date(end));

        while (iterator.hasNext()){
            WikipediaEditEvent event = iterator.next();
            long eventTimestamp = event.getTimestamp();
            long lateness = current - eventTimestamp;
            out.collect(String.format("%s lag %d ms", event.getUser(), lateness));
            valueHistogram.update(lateness);
            eventCounter.inc();
        }
    }
}
