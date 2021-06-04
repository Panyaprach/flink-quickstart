package org.example;

import org.apache.flink.api.common.eventtime.TimestampAssignerSupplier;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.restartstrategy.RestartStrategies;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.windowing.assigners.TumblingEventTimeWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.connectors.wikiedits.WikipediaEditEvent;
import org.apache.flink.streaming.connectors.wikiedits.WikipediaEditsSource;

import java.time.Duration;


public class StreamingJob {

    public static void main(String[] args) throws Exception {
        // set up the streaming execution environment
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
		env.setRestartStrategy(RestartStrategies
				.fixedDelayRestart(3, Time.seconds(10).toMilliseconds()));

		WatermarkStrategy<WikipediaEditEvent> wikiEditEventWatermarkStrategy = WatermarkStrategy.<WikipediaEditEvent>forBoundedOutOfOrderness(Duration.ofSeconds(5))
                .withIdleness(Duration.ofSeconds(10))
				.withTimestampAssigner(TimestampAssignerSupplier.of(((element, recordTimestamp) -> element.getTimestamp())));

        DataStream<WikipediaEditEvent> edits = env.addSource(new WikipediaEditsSource())
                .assignTimestampsAndWatermarks(wikiEditEventWatermarkStrategy);

        edits
				.keyBy(WikipediaEditEvent::getUser)
                .windowAll(TumblingEventTimeWindows.of(Time.seconds(5)))
                .allowedLateness(Time.seconds(1))
                .process(new UserLagProcessor())
                .print();
        // execute program
        env.execute("Flink Streaming Java API Skeleton");
    }
}
