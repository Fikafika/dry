import {Util} from 'bootstrap/js/dist/util.js'

$(document).on('click.bs.modal.data-api', '[data-show="modal"]', function (event) {
  var _this10 = this;

  var target;
  var selector = Util.getSelectorFromElement(this);

  if (selector) {
    target = document.querySelector(selector);
  }

  if (this.tagName === 'A' || this.tagName === 'AREA') {
    event.preventDefault();
  }

  var $target = $(target).one('show.bs.modal', function (showEvent) {
    if (showEvent.isDefaultPrevented()) {
      // Only register focus restorer if modal will actually get shown
      return;
    }

    $target.one('hidden.bs.modal', function () {
      if ($(_this10).is(':visible')) {
        _this10.focus();
      }
    });
  });

  $(target).modal('show');
  if ($(_this10).data('content')) {
    $(target).find('.modal-body').html($(_this10).data('content'));
  }
});

