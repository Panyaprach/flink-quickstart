package org.example;

import org.apache.flink.api.common.eventtime.Watermark;
import org.apache.flink.api.common.eventtime.WatermarkGenerator;
import org.apache.flink.api.common.eventtime.WatermarkOutput;
import org.apache.flink.streaming.connectors.wikiedits.WikipediaEditEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PunctuatedAssigner implements WatermarkGenerator<WikipediaEditEvent> {
    private static Logger log = LoggerFactory.getLogger(PunctuatedAssigner.class);

    @Override
    public void onEvent(WikipediaEditEvent event, long eventTimestamp, WatermarkOutput output) {
        log.info("Wiki: {}, Event: {}, Lag: ", event.getTimestamp(), eventTimestamp, eventTimestamp - event.getTimestamp());
        output.emitWatermark(new Watermark(event.getTimestamp()));
    }

    @Override
    public void onPeriodicEmit(WatermarkOutput output) {
        // don't need to do anything because we emit in reaction to events above
    }
}
