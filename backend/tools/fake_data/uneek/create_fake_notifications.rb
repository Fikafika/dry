#!/usr/local/bin/ruby

require File.expand_path('../../../config/environment', __dir__)

::UneekSsoClient.sync_all!
@schema = Dynamic::Schema.where(name: 'Uneek').first

@schema.load

@contact = User.first

D::Uneek::R::Notification.create([
  {
    title: 'Notification',
    body: 'Lorem ipsum, lorem ipsum',
  },
  {
    title: 'Notification pending',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'pending',
  },
  {
    title: 'Notification pending cancelable',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'pending',
    can_cancel: true,
  },
  {
    title: 'Notification canceled',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'finished',
    final_state: 'canceled',
  },
  {
    title: 'Notification canceled retryable',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'finished',
    final_state: 'canceled',
    can_retry: true,
  },
  {
    title: 'Notification  finished with success',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'finished',
    final_state: 'succeeded',
    can_cancel: true,
  },
  {
    title: 'Notification finished with failure',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'finished',
    final_state: 'failed',
  },
  {
    title: 'Notification finished with failure and errors',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'finished',
    final_state: 'failed',
    data_errors: [
      {
        record_id: 1,
        record_type: 'D::Uneek::Contact',
        details: [
          { last_name: [{error: 'blank'}] },
          { first_name: [{error: 'too_long', count: 2}] },
        ]
      },
    ],
    data: { record_id: 1, record_type: 'D::Uneek::Contact' },
  },
  {
    title: 'Notification finished with failure and exception',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'finished',
    final_state: 'failed',
    data_errors: [
      {
        type: "TypeError",
        message: "can't convert String into Integer",
        backtrace: ["source_code.rb:20"],
      },
    ],
    data: { record_id: 1, record_type: 'D::Uneek::Contact' },
  },
  {
    title: 'Notification finished with failure retryable',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'finished',
    final_state: 'failed',
    can_retry: true,
  },
  {
    title: 'Notification running',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'running',
  },
  {
    title: 'Notification running with progress',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'running',
    current: 10,
    total: 100,
  },
  {
    title: 'Notification running with progress suspendable',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'running',
    current: 20,
    total: 100,
    can_suspend: true,
  },
  {
    title: 'Notification running with progress suspendable and cancelable',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'running',
    current: 30,
    total: 100,
    can_suspend: true,
    can_cancel: true,
  },
  {
    title: 'Notification suspended',
    body: 'Lorem ipsum, lorem ipsum',
    state: 'suspended',
    current: 50,
    total: 100,
    can_suspend: true,
  },
  {
    title: 'Notification for document generation',
    klass_name: 'DocGen::Generation',
    state: 'finished',
    final_state: 'succeeded',
    data: {
      record_type: 'D::Uneek::Contact',
      record_id: '1',
      attachment: 'photo',
    }
  },
].map{|n| n[:user_id] = @contact.id; n }.reverse)

puts "finished"
