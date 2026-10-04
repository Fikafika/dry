import {parse,stringify} from 'scss-parser';  // expose-loader exposes parse and stringify
window.parse = parse; // :(
window.stringify = stringify;

import createQueryWrapper from 'query-ast';  // expose-loader exposes createQueryWrapper
window.createQueryWrapper = createQueryWrapper;

import { SketchPicker } from 'react-color';  // expose-loader exposes SketchPicker
window.SketchPicker = SketchPicker;

import downloadjs from 'downloadjs'; // expose-loader exposes download
window.download = downloadjs;
