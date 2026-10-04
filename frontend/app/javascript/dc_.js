import * as d3 from "d3"
import * as dc from "dc"

window.d3 = d3;

dc.CoordinateGridMixin.prototype._brushing = function (evt) {
    if (this._ignoreBrushEvents) {
        return;
    }

    let brushSelection = evt.selection;
    if (brushSelection) {
        brushSelection = brushSelection.map(this.x().invert);
    }

    brushSelection = this.extendBrush(brushSelection);

    this.redrawBrush(brushSelection, false);

    const rangedFilter = this.brushIsEmpty(brushSelection) ? null : dc.filters.RangedFilter(brushSelection[0], brushSelection[1]);

    if (evt.type == 'end') {
        dc.events.trigger(() => {
            this.applyBrushSelection(rangedFilter);
        }, dc.constants.EVENT_DELAY);
    }
}

if (dc.BarChart) {
  const original = dc.BarChart.prototype.fadeDeselectedArea;
  dc.BarChart.prototype.fadeDeselectedArea = function(brushSelection) {
    if (!this.chartBodyG()) return;
    if (original) original.call(this, brushSelection);
  }
}
window.dc = dc;
