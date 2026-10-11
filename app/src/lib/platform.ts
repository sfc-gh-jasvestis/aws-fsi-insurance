// Build option, set in the SPCS spec (snowflake/07_deploy_app.sql):
// 'snowflake' = Snowflake-only build (native FNOL claims simulator, Cortex AI_COMPLETE memo);
// 'aws' = AWS + Snowflake build (S3/Snowpipe claims feed, Bedrock memo, QuickSight).
export type DemoPlatform = 'snowflake' | 'aws';

export const demoPlatform = (): DemoPlatform => (process.env.DEMO_PLATFORM === 'snowflake' ? 'snowflake' : 'aws');
