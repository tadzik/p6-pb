use PB::Grammar;
use PB::Model::Field;
use PB::Model::Message;
use PB::Model::Option;
use PB::Model::Package;
use PB::Model::Enum;


class PB::Actions {
    method TOP($/) {
        make $<proto>.ast;
    }

    method proto($/) {
        make PB::Model::Package.new(
            name => $<pkg>[0]<dotted-ident>.Str,
            messages => $<message>>>.ast,
            options => $<option>>>.ast
        );
    }

    method option($/) {
        make $<opt-body>.ast;
    }

    method enum($/) {
        make PB::Model::Enum.new(
            name => $<ident>.Str,
            options => $<option>>>.ast,
            fields => $<enum-field>>>.ast
        );
    }

    method enum-field($/) {
        make PB::Model::EnumField.new(
            name => $<ident>.Str,
            value => $<int-lit>.Num.Int,
            options => $<fields-opts> ?? $<field-opts>.ast !! []
        );
    }

    method message($/) {
        make PB::Model::Message.new(
            name => $<ident>.Str,
            fields => $<message-body><field>>>.ast
        );
    }

    method field($/) {
        make PB::Model::Field.new(
            label => $<label>.Str, 
            type => $<type>.Str,
            name => $<ident>.Str,
            number => $<field-num>.Num.Int,
            options => $<field-opts> ?? $<field-opts>.ast !! []
        );
    }

    method field-opts($/) {
        make $<opt-body>>>.ast;
    }

    method field-opt($/) {
        make $<opt-body>.ast;
    }

    method opt-body($/) {
        say "constant: ", $<constant>.ast;
        make PB::Model::Option.new(
            name => $<opt-name>.Str,
            constant => $<constant> ?? $<constant>.ast !! Any
        );
    }

    method constant:sym<symbol>($/) {
        make $<ident>.Str;
    }

    ## string constants -------------------------------------------------------

    method constant:sym<str>($/) {
        make $<str-lit>.ast;
    }

    method str-lit:sym<single-quoted>($/) {
        make $<str-contents-single>>>.flat>>.ast.join;
    }

    method str-lit:sym<double-quoted>($/) {
        make $<str-contents-double>>>.flat>>.ast.join;
    }

    method str-contents-single($/) {
        if $<str-escape> {
            make $<str-escape>.ast;
        } else {
            make ~$/;
        }
    }

    method str-contents-double($/) {
        if $<str-escape> {
            make $<str-escape>.ast;
        } else {
            make ~$/;
        }
    }

    method str-escape:sym<hex>($/) {
        make chr(:16($<xdigit>.join));
    }

    method str-escape:sym<oct>($/) {
        make chr(:8($<digit>.join));
    }

    method str-escape:sym<char>($/) {
        my %h = {
            'n' => "\n",
            '\\' => "\\",
            # TODO: others...
        };
        make %h{~$<char>};
    }

    # number constants --------------------------------------------------------

    method constant:sym<int>($/) {
        make $<int-lit>.ast;
    }

    method int-lit:sym<dec>($/) {
        make $/.Str.Num;
    }

    method int-lit:sym<hex>($/) {
        make :16($<xdigit>.join);
    }

    method int-lit:sym<oct>($/) {
        make :8($<digit>.join);
    }

    method constant:sym<nan>($/) {
        make NaN;
    }

    method constant:sym<inf>($/) {
        if $<sign> && $<sign>.Str eq '-' {
            make -Inf;
        } else {
            make Inf;
        }
    }

    method constant:sym<bool>($/) {
        if $/.Str eq 'true' {
            make Bool::True;
        } else {
            make Bool::False;
        }
    }

    method constant:sym<float>($/) {
        make $/.Str.Num;
    }
}
