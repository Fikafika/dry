import 'datatables.net/js/jquery.dataTables'
import 'datatables.net-bs4/js/dataTables.bootstrap4'
import 'datatables.net-autofill/js/dataTables.autoFill'
import 'datatables.net-autofill-bs4/js/autoFill.bootstrap4'
import 'datatables.net-buttons/js/dataTables.buttons'
import 'datatables.net-buttons-bs4/js/buttons.bootstrap4'
import 'datatables.net-fixedcolumns-bs4/js/fixedColumns.bootstrap4'
import 'datatables.net-fixedcolumns/js/dataTables.fixedColumns'
import 'datatables.net-fixedheader-bs4/js/fixedHeader.bootstrap4'
import 'datatables.net-fixedheader/js/dataTables.fixedHeader'
import 'datatables.net-keytable-bs4/js/keyTable.bootstrap4'
import 'datatables.net-keytable/js/dataTables.keyTable'
import 'datatables.net-scroller-bs4/js/scroller.bootstrap4'
import 'datatables.net-scroller/js/dataTables.scroller'
import 'datatables.net-select/js/dataTables.select'
import 'datatables.net-select-bs4/js/select.bootstrap4'
import 'datatables.net-rowreorder/js/dataTables.rowReorder.js'
import './ColReorderWithResize'

$.fn.dataTable.Api.registerPlural( 'columns().names()', 'column().name()', function ( setter ) {
    return this.iterator( 'column', function ( settings, column ) {
        var col = settings.aoColumns[column];

        if ( setter !== undefined ) {
            col.sName = setter;
            return this;
        }
        else {
            return col.sName;
        }
    }, 1 );
} );

$.fn.dataTable.RowReorder.prototype._mouseMove = function (e) {
    this._clonePosition(e);

    var start = this.s.start;
    var cancelable = this.c.cancelable;

    // Lionel: I added dropIsAllowed in order to prevent drop at wrong places
    if (this.c.dropIsAllowed)
      cancelable = true;

    if (cancelable) {
        var bodyArea = this.s.bodyArea;
        var cloneArea = this._calcCloneParentArea();

        this.s.dropAllowed = this._rectanglesIntersect(bodyArea, cloneArea);
        $(this.dom.cloneParent).toggleClass('drop-not-allowed', !this.s.dropAllowed);
    }

    // Transform the mouse position into a position in the table's body
    var bodyY = this._eventToPage(e, 'Y') - this.s.bodyTop;
    var middles = this.s.middles;
    var insertPoint = null;

    // Determine where the row should be inserted based on the mouse
    // position
    for (var i = 0, ien = middles.length; i < ien; i++) {
        if (bodyY < middles[i]) {
            insertPoint = i;
            break;
        }
    }

    if (insertPoint === null) {
        insertPoint = middles.length;
    }

    // Lionel: I added dropIsAllowed in order to prevent drop at wrong places
    if (this.c.dropIsAllowed && this.s.dropAllowed) {
        let dt = this.s.dt;
        let origin = dt.row(this.dom.target);

        let target = dt.row((idx, data) => data.row_position === insertPoint);

        if (!this.c.dropIsAllowed(insertPoint, origin, target)) {
            this.s.dropAllowed = false;
        }
    }

    if (cancelable) {
      if (!this.s.dropAllowed) {
        // Move the row back to its original position becasuse the drop is not allowed
        insertPoint =
            start.rowIndex > this.s.lastInsert ? start.rowIndex + 1 : start.rowIndex;
        }

        this.dom.target.toggleClass('dt-rowReorder-moving', this.s.dropAllowed);
    }

    this._moveTargetIntoPosition(insertPoint);

    this._shiftScroll(e);
}
