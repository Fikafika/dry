require 'active_support/concern'

module Dynamo
  module Banner; extend ActiveSupport::Concern
    included do
      def output_header(mode)
        print_banner
        super(mode)
      end

      def print_banner
        log("
                                                 .....
                                            ..oooxxxxxooo.
                                       ...ooxxxxoooooooxxxo.
                                   ..ooxxxxxxo..       .oxxxo
                              ..ooxxxxxooxxxo.           .oxxo
                         ..ooxxxxxoo..  .xxo.    .ooo     .xxx.
                     ..ooxxxxoo...      oxxo     oxxxo    .oxx.
                 .ooxxxxoo...           .xxx.    ..o.     .xxx.
                 oxooo..                 oxxo.           .oxxo
        ......                            oxxxo.       .oxxxo
    .ooxxxxxxxxo.                          .ooxxxoooooxxxoo.
   oxxxo......oxxo.                           ..ooooooo..
  .xxx.        oxxx.              ....oo.....            oxo
  oxxo   .xo.  .oxx.         .oooxxxxxxxxxxxxoo..       .xxo
  oxxo   .o.   .xxx.      .ooxxxooo........oooxxxo..    oxxo
  .xxxo.      .oxxo     .oxxxo..              .ooxxxo  .oxx.
   .oxxxooooooxxxo     oxxxo.        .oo.        .oxxo..xxo.
     .oxxxxxxxoo.     oxxx.    ...   .xxo   ...    oxxxxxxo
       .oxxxo.       oxxo.    .xxxo..oxxx..oxxx.    oxxxxx.
         oxxxo.     .xxx.      .oxxxxxxxxxxxxo.      oxxxx.
          .oxxxo.   oxxo     ....oxxo....oxxx....    .xxxo
            ..oxxo  oxxo   .oxxxxxxx.    .xxxxxxxo.  .xxxo
               .o.  oxxo    .....oxxo....oxxxo...    .xxx.
                    .xxx.      .ooxxxxxxxxxxxo.      oxxo
                     oxxx.    .xxxxo.oxxx..oxxx.    .xxx.
                      oxxx.   ..o.   .xxo   ...    oxxx.
                       .xxxo.        .oo.        .oxxo.
                        .oxxxo..              .ooxxxo
                          .oxxxxooo........oooxxxoo.
                             .ooxxxxxxxxxxxxxxoo.
                                 ....oooo....
        ")
      end
    end
  end
end

require 'puma/single'
Puma::Single.include Dynamo::Banner
require 'puma/cluster'
Puma::Cluster.include Dynamo::Banner
