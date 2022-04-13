function cmpstruct(A, B, varargin)
    
    assert(isstruct(A), 'input A must be a struct');
    assert(isstruct(B), 'input B must be a struct');
    
    if nargin > 2
        prepath = varargin{1};
    else 
        prepath = "";
    end
    
    fnA = fieldnames(A);
    fnB = fieldnames(B);

    onlyA = setdiff(fnA, fnB);
    onlyB = setdiff(fnB, fnA);
    
    cellfun(@(x)fprintf('only in A: %s.%s\n', prepath, x), onlyA); 
    cellfun(@(x)fprintf('only in B: %s.%s\n', prepath, x), onlyB);
    
    both = intersect(fnA, fnB);
    
    for idx = 1:length(both)
        
        eq = false;
        
        if isstruct(A.(both{idx})) && isstruct(B.(both{idx}))
            cmpstruct(A.(both{idx}), B.(both{idx}), strcat(".", both{idx}));
            eq = true;
        elseif isstruct(A.(both{idx})) || isstruct(B.(both{idx}))
            eq = false;
        elseif isequal(A.(both{idx}), B.(both{idx}))
            eq = true;
        end
        
        if ~eq
            fprintf('different: %s.%s\n', prepath, both{idx});
        end
        
    end
            
