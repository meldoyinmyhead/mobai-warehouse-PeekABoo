import json
import os

# Path to the notebook
notebook_path = r'd:\Warehouse\mobai-warehouse-PeekABoo\ai\notebooks\Forecasting\05_enhanced_forecasting_pipeline.ipynb'

with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

# 1. Update Cell 12 (Baseline functions)
baseline_cell_index = -1
for i, cell in enumerate(nb['cells']):
    if cell['cell_type'] == 'code' and any('weighted_moving_average' in line for line in cell['source']):
        baseline_cell_index = i
        break

if baseline_cell_index != -1:
    nb['cells'][baseline_cell_index]['source'] = [
        "def weighted_moving_average_add(product_id, forecast_date, history_df, num_weeks=4):\n",
        "    '''\n",
        "    ADD-corrected Weighted Moving Average for Segment C.\n",
        "    '''\n",
        "    start_date = forecast_date - pd.Timedelta(weeks=num_weeks)\n",
        "    hist = history_df[\n",
        "        (history_df['id_produit'] == product_id) & \n",
        "        (history_df['date'] >= start_date) & \n",
        "        (history_df['date'] < forecast_date)\n",
        "    ].copy()\n",
        "    \n",
        "    if len(hist) == 0: return 0\n",
        "    \n",
        "    hist['weeks_ago'] = hist['date'].apply(lambda x: (forecast_date - x).days // 7)\n",
        "    weekly_summary = hist.groupby('weeks_ago')['quantite_demande'].sum().reset_index()\n",
        "    \n",
        "    all_weeks = pd.DataFrame({'weeks_ago': range(num_weeks)})\n",
        "    weekly_summary = all_weeks.merge(weekly_summary, on='weeks_ago', how='left').fillna(0)\n",
        "    \n",
        "    weights = np.array([0.4, 0.3, 0.2, 0.1])[:min(num_weeks, len(weekly_summary))]\n",
        "    weights = weights / weights.sum()\n",
        "    \n",
        "    # Sort weeks_ago from newest (0) to oldest (3)\n",
        "    # We want newest (weeks_ago=0) to have weights[0]\n",
        "    weekly_vals = weekly_summary.sort_values('weeks_ago')['quantite_demande'].values\n",
        "    weekly_avg = np.average(weekly_vals, weights=weights)\n",
        "    \n",
        "    return max(0, round(weekly_avg / 7))\n",
        "\n",
        "def naive_forecast_add(product_id, forecast_date, history_df, window=30):\n",
        "    '''\n",
        "    ADD-corrected Naive Forecast for Segment D.\n",
        "    '''\n",
        "    start_date = forecast_date - pd.Timedelta(days=window)\n",
        "    hist = history_df[\n",
        "        (history_df['id_produit'] == product_id) & \n",
        "        (history_df['date'] >= start_date) & \n",
        "        (history_df['date'] < forecast_date)\n",
        "    ]\n",
        "    \n",
        "    if len(hist) == 0: return 0\n",
        "    return max(0, round(hist['quantite_demande'].sum() / window))\n",
        "\n",
        "print('✅ Updated ADD Baseline functions defined')"
    ]

# 2. Add New Section: Walk-Forward Validation
new_cells = [
    {
        "cell_type": "markdown",
        "metadata": {},
        "source": [
            "## 7. 🔄 Daily Orchestration: Walk-Forward Validation\n",
            "\n",
            "This section implements a manual backtest that simulates daily re-training and forecasting for the last 30 days."
        ]
    },
    {
        "cell_type": "code",
        "metadata": {},
        "source": [
            "def simulate_daily_forecast(data_df, feature_cols, start_date, end_date):\n",
            "    results = []\n",
            "    current_date = pd.to_datetime(start_date)\n",
            "    end_dt = pd.to_datetime(end_date)\n",
            "    \n",
            "    print(f'🚀 Starting Walk-Forward Simulation from {start_date.date()} to {end_date.date()}...')\n",
            "    \n",
            "    while current_date <= end_dt:\n",
            "        train_data = data_df[data_df['date'] < current_date].copy()\n",
            "        test_day_data = data_df[data_df['date'] == current_date].copy()\n",
            "        \n",
            "        if len(test_day_data) == 0:\n",
            "            current_date += pd.Timedelta(days=1)\n",
            "            continue\n",
            "            \n",
            "        # Tier 1: A & B\n",
            "        t1_train = train_data[train_data['segment'].str.contains('HIGH_FREQ')]\n",
            "        t1_test = test_day_data[test_day_data['segment'].str.contains('HIGH_FREQ')]\n",
            "        \n",
            "        if len(t1_train) > 0 and len(t1_test) > 0:\n",
            "            model = XGBRegressor(n_estimators=300, learning_rate=0.05, max_depth=6, n_jobs=-1, random_state=42)\n",
            "            X_train = t1_train[feature_cols].copy()\n",
            "            X_test_day = t1_test[feature_cols].copy()\n",
            "            \n",
            "            for col in X_train.columns:\n",
            "                if X_train[col].dtype == 'object':\n",
            "                    X_train[col] = (X_train[col] == 'Oui').astype(int)\n",
            "                    X_test_day[col] = (X_test_day[col] == 'Oui').astype(int)\n",
            "            \n",
            "            model.fit(X_train.astype(float).fillna(0), t1_train['quantite_demande'])\n",
            "            t1_test['forecast'] = np.maximum(0, model.predict(X_test_day.astype(float).fillna(0)))\n",
            "            results.append(t1_test[['id_produit', 'date', 'segment', 'quantite_demande', 'forecast']])\n",
            "        \n",
            "        # Baselines: C & D\n",
            "        other_test = test_day_data[~test_day_data['segment'].str.contains('HIGH_FREQ')].copy()\n",
            "        if len(other_test) > 0:\n",
            "            preds = []\n",
            "            for _, row in other_test.iterrows():\n",
            "                if 'MEDIUM_FREQ' in row['segment']:\n",
            "                    p = weighted_moving_average_add(row['id_produit'], current_date, train_data)\n",
            "                else:\n",
            "                    p = naive_forecast_add(row['id_produit'], current_date, train_data)\n",
            "                preds.append(p)\n",
            "            other_test['forecast'] = preds\n",
            "            results.append(other_test[['id_produit', 'date', 'segment', 'quantite_demande', 'forecast']])\n",
            "            \n",
            "        print(f'  ✅ Date {current_date.date()} processed.')\n",
            "        current_date += pd.Timedelta(days=1)\n",
            "    \n",
            "    return pd.concat(results).reset_index(drop=True)\n",
            "\n",
            "backtest_start = daily_demand['date'].max() - pd.Timedelta(days=30)\n",
            "backtest_end = daily_demand['date'].max()\n",
            "\n",
            "all_results = simulate_daily_forecast(daily_demand, feature_cols, backtest_start, backtest_end)\n",
            "\n",
            "total_actual = all_results['quantite_demande'].sum()\n",
            "total_abs_error = np.abs(all_results['quantite_demande'] - all_results['forecast']).sum()\n",
            "total_bias = (all_results['forecast'] - all_results['quantite_demande']).sum()\n",
            "\n",
            "print(f'\\n📊 Final Walk-Forward Metrics (30 days):')\n",
            "print(f'  Cumulative WAPE: {total_abs_error / total_actual:.2%}')\n",
            "print(f'  Cumulative Bias: {total_bias / total_actual:.2%}')"
        ]
    }
]

nb['cells'].extend(new_cells)

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print('Notebook updated successfully.')
",Complexity:1,Description:
