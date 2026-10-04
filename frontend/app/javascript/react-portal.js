import React from 'react';
import {createPortal} from 'react-dom';

function Portal({children, parentSelector = 'body', id}) {

  let parent = $(parentSelector).length > 0 ? $(parentSelector)[0] : document.body;

  let wrapper = $('#'+id)
  if(wrapper.length == 0) wrapper = $('<div></div>').attr('class', "portal").attr('id', id).appendTo(parent)

  return ( createPortal(children, wrapper[0]) );
}

export default Portal;