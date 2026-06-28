# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    format: 'A4',
    margin: {
      top: '12mm',
      bottom: '12mm',
      left: '10mm',
      right: '10mm'
    },
    print_background: true,
    prefer_css_page_size: true,
    executable_path: ENV.fetch('GROVER_EXECUTABLE_PATH', '/usr/bin/chromium'),
    launch_args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
end
