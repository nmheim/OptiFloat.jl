import{_ as i,c as s,o as e,a7 as a}from"./chunks/framework.8xnqe1GN.js";const u=JSON.parse('{"title":"API","description":"","frontmatter":{},"headers":[],"relativePath":"api.md","filePath":"api.md","lastUpdated":null}'),t={name:"api.md"},p=a(`<h1 id="api" tabindex="-1">API <a class="header-anchor" href="#api" aria-label="Permalink to &quot;API&quot;">​</a></h1><p>API Documentation of OptiFloat.jl</p><div style="border-width:1px;border-style:solid;border-color:black;padding:1em;border-radius:25px;"><a id="DynamicExpressions.ParseModule.parse_expression-Tuple{Type{&lt;:AbstractFloat}, Expr}" href="#DynamicExpressions.ParseModule.parse_expression-Tuple{Type{&lt;:AbstractFloat}, Expr}">#</a> <b><u>DynamicExpressions.ParseModule.parse_expression</u></b> — <i>Method</i>. <div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">parse_expression</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(T</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Type{&lt;:AbstractFloat}</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, expr</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Expr</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; kws</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Parse a Julia <code>Expr</code> to a dynamic <code>Expression</code> that can be used to efficiently compute <code>local_error</code>s.</p><p><a href="https://github.com/nmheim/OptiFloat.jl" target="_blank" rel="noreferrer">source</a></p></div><br><div style="border-width:1px;border-style:solid;border-color:black;padding:1em;border-radius:25px;"><a id="OptiFloat.infer_regimes-Union{Tuple{T}, Tuple{Union{Vector{&lt;:OptiFloat.Candidate}, Vector{&lt;:OptiFloat.Regime}}, Int64, Matrix{T}}} where T" href="#OptiFloat.infer_regimes-Union{Tuple{T}, Tuple{Union{Vector{&lt;:OptiFloat.Candidate}, Vector{&lt;:OptiFloat.Regime}}, Int64, Matrix{T}}} where T">#</a> <b><u>OptiFloat.infer_regimes</u></b> — <i>Method</i>. <div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">infer_regimes</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(candidates</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Vector{&lt;:Candidate}</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, feature</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Int</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, points</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Matrix{T}</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; kws</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Pick as few candidates and their corresponding good regimes to define a <code>PiecewiseRegime</code> that represents an expression that performs well on all <code>points</code>.</p><p><a href="https://github.com/nmheim/OptiFloat.jl" target="_blank" rel="noreferrer">source</a></p></div><br><div style="border-width:1px;border-style:solid;border-color:black;padding:1em;border-radius:25px;"><a id="OptiFloat.logsample-Tuple{DynamicExpressions.ExpressionModule.Expression, Int64}" href="#OptiFloat.logsample-Tuple{DynamicExpressions.ExpressionModule.Expression, Int64}">#</a> <b><u>OptiFloat.logsample</u></b> — <i>Method</i>. <div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">logsample</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(expr</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Expression</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, batchsize</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Int</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; eval_exact</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">true</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Sample valid inputs to <code>expr</code>. If <code>eval_exact=false</code> <code>expr</code> is evaluated with <code>BigFloat</code>s so samples might be generated that cause overflow in the original floating point type of <code>expr</code>.</p><p><a href="https://github.com/nmheim/OptiFloat.jl" target="_blank" rel="noreferrer">source</a></p></div><br><div style="border-width:1px;border-style:solid;border-color:black;padding:1em;border-radius:25px;"><a id="OptiFloat.optifloat!-Union{Tuple{T}, Tuple{Vector{&lt;:OptiFloat.Candidate}, Matrix{T}}} where T" href="#OptiFloat.optifloat!-Union{Tuple{T}, Tuple{Vector{&lt;:OptiFloat.Candidate}, Matrix{T}}} where T">#</a> <b><u>OptiFloat.optifloat!</u></b> — <i>Method</i>. <div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">optifloat!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(candidates</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Vector{&lt;:Candidate}</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, points</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Matrix{T}</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">where</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> {T}</span></span></code></pre></div><p>Try to find better candidate expressions than the ones that are already present in <code>candidates</code>. The first unused candidate will be attempted to improve and new candidate expression are added to <code>candidates</code>. Once a candidate is picked, this function goes through the following steps:</p><ol><li><p>Given an initial expression <code>candidate</code>, compute the <code>local_error</code> of every subexpression and pick the subexpression <code>sub_expr</code> with the worst error for further analysis.</p></li><li><p>Recursively rewrite the <code>sub_expr</code> based on a <em>set of rewrite rules</em>, generating a number of new candidates.</p></li><li><p>Simplify the candidates via equality saturation (implemented in Metatheory.jl)</p></li><li><p>Compute error of new candidates and add every candidate that performs better on any of the <code>points</code> to the existing list.</p></li></ol><p><a href="https://github.com/nmheim/OptiFloat.jl" target="_blank" rel="noreferrer">source</a></p></div><br><div style="border-width:1px;border-style:solid;border-color:black;padding:1em;border-radius:25px;"><a id="OptiFloat.print_report-Tuple{OptiFloat.Candidate, OptiFloat.PiecewiseRegime}" href="#OptiFloat.print_report-Tuple{OptiFloat.Candidate, OptiFloat.PiecewiseRegime}">#</a> <b><u>OptiFloat.print_report</u></b> — <i>Method</i>. <div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_report</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(original</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Candidate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, rs</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">PiecewiseRegime</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; rm_ansi</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">false</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Output a report including a copy-pasteable function representing the <code>PiecewiseRegime</code>.</p><p><a href="https://github.com/nmheim/OptiFloat.jl" target="_blank" rel="noreferrer">source</a></p></div><br><div style="border-width:1px;border-style:solid;border-color:black;padding:1em;border-radius:25px;"><a id="OptiFloat.sample_finite-Tuple{Function, Function, Type, Int64, Int64}" href="#OptiFloat.sample_finite-Tuple{Function, Function, Type, Int64, Int64}">#</a> <b><u>OptiFloat.sample_finite</u></b> — <i>Method</i>. <p>Generate samples from <code>samplefn</code> that yield finite results when called with <code>testfn</code>:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> samplefn</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(T, inputsize)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">y </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> testfn</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x)  </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&lt;--</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> add to samples </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">if</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> isfinite</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(y)</span></span></code></pre></div><p><a href="https://github.com/nmheim/OptiFloat.jl" target="_blank" rel="noreferrer">source</a></p></div><br>`,14),l=[p];function n(r,o,d,h,k,c){return e(),s("div",null,l)}const E=i(t,[["render",n]]);export{u as __pageData,E as default};