export const indexTemplate = {
  index_patterns: ['recipejoe-logs-*'],
  template: {
    settings: {
      number_of_shards: 1,
      number_of_replicas: 0, // Single node, no replicas needed
      'index.lifecycle.name': 'recipejoe-logs-policy',
    },
    mappings: {
      properties: {
        '@timestamp': { type: 'date' },
        id: { type: 'keyword' },
        provider: { type: 'keyword' },
        project_ref: { type: 'keyword' },
        event_message: { type: 'text' },

        // Edge logs / API Gateway specific
        'metadata.request.method': { type: 'keyword' },
        'metadata.request.path': { type: 'keyword' },
        'metadata.request.cf.country': { type: 'keyword' },
        'metadata.response.status_code': { type: 'integer' },

        // Postgres logs specific
        error_severity: { type: 'keyword' },
        user_name: { type: 'keyword' },
        database_name: { type: 'keyword' },
        command_tag: { type: 'keyword' },

        // Auth logs specific
        'metadata.action': { type: 'keyword' },
        'metadata.actor_id': { type: 'keyword' },

        // Edge function specific
        'metadata.function_id': { type: 'keyword' },
        'metadata.execution_time_ms': { type: 'integer' },
      },
    },
  },
};

export const ilmPolicy = {
  policy: {
    phases: {
      hot: {
        min_age: '0ms',
        actions: {
          rollover: {
            max_size: '5gb',
            max_age: '30d',
          },
        },
      },
      delete: {
        min_age: '90d',
        actions: {
          delete: {},
        },
      },
    },
  },
};
