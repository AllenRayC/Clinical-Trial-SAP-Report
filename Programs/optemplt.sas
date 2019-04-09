libname odspath "&xdir.Programs";

ods path odspath.templat(UPDATE) sashelp.tmplmst(READ) ;

proc template ;
   define style TStyleRTF ;
      parent=styles.rtf ;

      style table from table /
         Background=_UNDEF_
         rules=groups   /* PUTS BOTTOM BORDER ON ROW HEADERS */
         frame=void
         cellspacing=1.0
         cellpadding=1.0
         borderwidth=1pt
         ;

      replace fonts /
         'TitleFont2'         = ("Times New Roman",10pt)
         'TitleFont'          = ("Times New Roman",10pt)
         'StrongFont'         = ("Times New Roman",10pt)
         'EmphasisFont'       = ("Times New Roman",10pt,Italic)
         'FixedEmphasisFont'  = ("Times New Roman",10pt,Italic)
         'FixedStrongFont'    = ("Times New Roman",10pt)
         'FixedHeadingFont'   = ("Times New Roman",10pt)
         'BatchFixedFont'     = ("Times New Roman",10pt)
         'FixedFont'          = ("Times New Roman",10pt)
         'headingEmphasisFont'= ("Times New Roman",10pt,Italic)
         'headingFont'        = ("Times New Roman",10pt)    /* FONT FOR COLUMN HEADERS */
         'docFont'            = ("Times New Roman",9pt)
         ;

      replace Body from Document /
         bottommargin = 0.75in
         topmargin    = 0.75in
         rightmargin  = 1in
         leftmargin   = 1in
         ;

      replace HeadersAndFooters from cell /
         font = fonts('HeadingFont')
         foreground = _undef_/*colors('headerfg')*/
         background = _undef_/*lightgrey*/
         ;

      replace TitlesAndFooters from Container /
         font = Fonts('TitleFont')
         background = _undef_
         foreground = _undef_/*colors('headerfg')*/
         rules = ALL
         just  = CENTER
         ;

      replace PageNo from Container /
         font        = Fonts('docFont')
         background  = colors('systitlebg')
         foreground  = colors('systitlefg')
         cellspacing = 0
         cellpadding = 0
         ;

   end ;
run ;
