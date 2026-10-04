
$(document).on('click', '.dropdown-menu a.dropdown-toggle', function (event) {
  $(this).parent().siblings().addClass('dropright');
  $(this).parent().toggleClass('dropright');
  $(this).parent().siblings().find('.wrapper.show').toggleClass("show");
  var $parent = $(this).parents('ul').first();
  var $subMenu = $(this).next(".wrapper");
  $subMenu.toggleClass('show');
  $(this).parents('li.nav-item.dropdown.show').on('hidden.bs.dropdown', function(e) {
    $('.dropdown-submenu .show').removeClass("show");
  });
  $submenuWrapper = $(this);
  var menuItemPos = $submenuWrapper[0].getBoundingClientRect();
  $subMenu.css({
    top: menuItemPos.top - 50,
    left: menuItemPos.left + Math.round($parent.outerWidth() * 0.98)
  });
  return false;
});