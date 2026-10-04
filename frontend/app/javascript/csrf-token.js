$(() => {
  $(document).ajaxComplete((event, xhr, settings ) => {
    const headerToken = xhr.getResponseHeader('X-CSRF-Token');
    if (headerToken)
      $('meta[name=csrf-token]').attr('content', headerToken);
  });
});
