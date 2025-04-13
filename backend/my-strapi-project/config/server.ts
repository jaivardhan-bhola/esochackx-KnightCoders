export default ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', 7123),
  app: {
    keys: env.array('APP_KEYS'),
  },
});
