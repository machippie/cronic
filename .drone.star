def main(ctx):
  return [
    linting(ctx),
    readme(ctx),
    notify(ctx),
  ]

def linting(ctx):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'linting',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'later',
        'image': 'xoxys/ansible-later:latest',
        'pull': 'always',
        'commands': [
          'ansible-later',
        ],
      },
    ],
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }

def readme(ctx):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'readme',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'doctor',
        'image': 'xoxys/ansible-doctor:latest',
        'pull': 'always',
        'environment': {
          'ANSIBLE_DOCTOR_LOG_LEVEL': 'INFO',
          'ANSIBLE_DOCTOR_FORCE_OVERWRITE': True,
          'ANSIBLE_DOCTOR_EXCLUDE_FILES': 'molecule/',
          'ANSIBLE_DOCTOR_TEMPLATE_DIR': 'doctor',
          'ANSIBLE_DOCTOR_TEMPLATE': 'jekyll',
          'ANSIBLE_DOCTOR_OUTPUT_DIR': 'doctor/publish',
        },
      },
      {
        'name': 'publish',
        'image': 'plugins/gh-pages:latest',
        'pull': 'always',
        'settings': {
          'username': {
            'from_secret': 'github_username',
          },
          'password': {
            'from_secret': 'github_token',
          },
          'pages_directory': 'doctor/publish/',
        },
        'when': {
          'ref': [
            'refs/heads/master',
          ],
        },
      },
    ],
    'depends_on': [
      'linting',
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
        'refs/pull/**',
      ],
    },
  }

def notify(ctx):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'notify',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'matrix',
        'image': 'plugins/matrix:latest',
        'pull': 'always',
        'settings': {
          'username': {
            'from_secret': 'matrix_username',
          },
          'password': {
            'from_secret': 'matrix_password',
          },
          'roomid': {
            'from_secret': 'matrix_roomid',
          },
          'homeserver': 'https://matrix.org',
        },
      },
    ],
    'depends_on': [
      'linting',
      'readme',
    ],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
      'status': [
        'failure'
      ],
    },
  }
