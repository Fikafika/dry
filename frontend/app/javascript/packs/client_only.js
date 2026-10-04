//app/javascript/packs/client_only.js
// add any requires for packages that will run client side only
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

// jQuery dependencies ----------------

import 'jquery'; // expose-loader exposes $ and jQuery from jquery

import Rails from '@rails/ujs'
Rails.start();

import 'csrf-token';

import * as ActiveStorage from "@rails/activestorage";
window.ActiveStorage = ActiveStorage;
ActiveStorage.start();

import "channels";
import '../channels/consumer'; // expose-loader exposes ApiCable

import 'popper.js';
import 'bootstrap';
import '../responsiveTabs';

import TomSelect from 'tom-select';
window.TomSelect = TomSelect;

import '../datetime-picker';

import 'jquery-deparam';

import '../modal-show';
import '../multilevel-dropdown';
import '../datatables.net';

import 'data-confirm-modal';

import IconSelector from "icon-selector";
IconSelector.start();

import jsonToFormData from 'json-form-data';
window.jsonToFormData = jsonToFormData;

import '../dc_';

import parsePhoneNumber from 'libphonenumber-js';
window.parsePhoneNumber = parsePhoneNumber;

// React Dependencies -------------------

import * as React from 'react';
window.React = React;
import createReactClass from 'create-react-class';
window.createReactClass = createReactClass;

import * as ReactDOM from 'react-dom';
window.ReactDOM = ReactDOM;

import * as History from 'history';
window.History = History;
import * as ReactRouter from 'react-router';
window.ReactRouter = ReactRouter;
import * as ReactRouterDOM from 'react-router-dom';
window.ReactRouterDOM = ReactRouterDOM
import * as ReactRailsUJS from 'react_ujs';
window.ReactRailsUJS = ReactRailsUJS;

import { uuidv7 } from "uuidv7";
window.uuidv7 = uuidv7;

import { FormEditor } from 'uneek_form_editor';
window.FormEditor = FormEditor;
import 'uneek_form_editor/dist/index.esm.css'

import '../tinymce';

import withMeasure from '../withMeasure';
window.withMeasure = withMeasure;

import * as ReactGridLayout from 'react-grid-layout';
window.ReactGridLayout = ReactGridLayout;

import { MessageEditorReact } from 'uneek_message_editor';
window.UneekMessageEditor = MessageEditorReact;
import 'uneek_message_editor/dist/index.esm.css'
import Portal from '../react-portal';
window.Portal = Portal;

import '../bootstrap_editor';

// Other dependencies -------------------

import QRCode from 'qrcode';
window.QRCode = QRCode;

import { split } from 'split-sms';
window.splitSms = split;

import { SourceMapConsumer } from '@jridgewell/source-map';
window.SourceMapConsumer = SourceMapConsumer;

if (process.env.NODE_ENV === 'test') {
  require('mock-xmlhttprequest');
}

// FullCalendar plugins
import FullCalendar from '@fullcalendar/react';
window.FullCalendar = FullCalendar;

import bootstrapPlugin from '@fullcalendar/bootstrap';
window.bootstrapPlugin = bootstrapPlugin;

import interactionPlugin, { Draggable } from '@fullcalendar/interaction';
window.FullCalendarInteraction = interactionPlugin;
window.FullCalendarDraggable = Draggable;

import resourceTimelinePlugin from '@fullcalendar/resource-timeline';
window.FullCalendarResourceTimeline = resourceTimelinePlugin;

import listPlugin from '@fullcalendar/list';
window.FullCalendarList = listPlugin;

import timegridPlugin from '@fullcalendar/timegrid';
window.FullCalendarTimegrid = timegridPlugin;

import daygridPlugin from '@fullcalendar/daygrid';
window.FullCalendarDayGrid = daygridPlugin;


// to add additional NPM packages run `yarn add package-name@version`
// then add the require here.
