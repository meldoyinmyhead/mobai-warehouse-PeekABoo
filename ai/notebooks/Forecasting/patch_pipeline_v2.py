import json
import os

notebook_path = r'd:\Warehouse\mobai-warehouse-PeekABoo\ai\notebooks\Forecasting\05_enhanced_forecasting_pipeline.ipynb'

with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

# Update cell 12
for i, cell in enumerate(nb['cells']):
    if cell['cell_type'] == 'code' and any('weighted_moving_average' in line for line in cell['source']):
        nb['cells'][i]['source'] = [
            "def weighted_moving_average_add(product_id, forecast_date, history_df, num_weeks=4):\n",
            "    start_date = forecast_date - pd.Timedelta(weeks=num_weeks)\n",
            "    hist = history_df[(history_df['id_produit'] == product_id) & (history_df['date'] >= start_date) & (history_df['date'] < forecast_date)].copy()\n",
            "    if len(hist) == 0: return 0\n",
            "    hist['weeks_ago'] = hist['date'].apply(lambda x: (forecast_date - x).days // 7)\n",
            "    weekly_summary = hist.groupby('weeks_ago')['quantite_demande'].sum().reset_index()\n",
            "    all_weeks = pd.DataFrame({'weeks_ago': range(num_weeks)})\n",
            "    weekly_summary = all_weeks.merge(weekly_summary, on='weeks_ago', how='left').fillna(0)\n",
            "    weights = np.array([0.4, 0.3, 0.2, 0.1])[:min(num_weeks, len(weekly_summary))]\n",
            "    weights = weights / weights.sum()\n",
            "    weekly_vals = weekly_summary.sort_values('weeks_ago')['quantite_demande'].values\n",
            "    weekly_avg = np.average(weekly_vals, weights=weights)\n",
            "    return max(0, round(weekly_avg / 7))\n",
            "\n",
            "def naive_forecast_add(product_id, forecast_date, history_df, window=30):\n",
            "    start_date = forecast_date - pd.Timedelta(days=window)\n",
            "    hist = history_df[(history_df['id_produit'] == product_id) & (history_df['date'] >= start_date) & (history_df['date'] < forecast_date)]\n",
            "    if len(hist) == 0: return 0\n",
            "    return max(0, round(hist['quantite_demande'].sum() / window))\n",
            "\n",
            "print('✅ Updated ADD Baseline functions defined')"
        ]
        break

# Orchestration cell
orchestration_cell = {
    "cell_type": "code",
    "metadata": {},
    "source": [
        "def simulate_daily_forecast(data_df, feature_cols, start_date, end_date):\n",
        "    results = []\n",
        "    current_date = pd.to_datetime(start_date)\n",
        "    end_dt = pd.to_datetime(end_date)\n",
        "    print(f'🚀 Starting Walk-Forward Simulation from {start_date.date()} to {end_date.date()}...')\n",
        "    while current_date <= end_dt:\n",
        "        train_data = data_df[data_df['date'] < current_date].copy()\n",
        "        test_day_data = data_df[data_df['date'] == current_date].copy()\n",
        "        if len(test_day_data) == 0:\n",
        "            current_date += pd.Timedelta(days=1)\n",
        "            continue\n",
        "        t1_train = train_data[train_data['segment'].str.contains('HIGH_FREQ')]\n",
        "        t1_test = test_day_data[test_day_data['segment'].str.contains('HIGH_FREQ')]\n",
        "        if len(t1_train) > 0 and len(t1_test) > 0:\n",
        "            from xgboost import XGBRegressor\n",
        "            model = XGBRegressor(n_estimators=100, learning_rate=0.1, max_depth=6, n_jobs=-1, random_state=42)\n",
        "            X_train = t1_train[feature_cols].copy()\n",
        "            X_test_day = t1_test[feature_cols].copy()\n",
        "            for col in X_train.columns:\n",
        "                if X_train[col].dtype == 'object':\n",
        "                    X_train[col] = (X_train[col] == 'Oui').astype(int)\n",
        "                    X_test_day[col] = (X_test_day[col] == 'Oui').astype(int)\n",
        "            model.fit(X_train.astype(float).fillna(0), t1_train['quantite_demande'])\n",
        "            t1_test['forecast'] = np.maximum(0, model.predict(X_test_day.astype(float).fillna(0)))\n",
        "            results.append(t1_test[['id_produit', 'date', 'segment', 'quantite_demande', 'forecast']])\n",
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
        "        print(f'  ✅ Date {current_date.date()} processed.')\n",
        "        current_date += pd.Timedelta(days=1)\n",
        "    return pd.concat(results).reset_index(drop=True)\n",
        "\n",
        "backtest_start = daily_demand['date'].max() - pd.Timedelta(days=30)\n",
        "backtest_end = daily_demand['date'].max()\n",
        "all_results = simulate_daily_forecast(daily_demand, feature_cols, backtest_start, backtest_end)\n",
        "total_actual = all_results['quantite_demande'].sum()\n",
        "total_abs_error = np.abs(all_results['quantite_demande'] - all_results['forecast']).sum()\n",
        "print(f'\\n📊 Cumulative WAPE (30 days): {total_abs_error / total_actual:.2%}')"
    ]
}

nb['cells'].append(orchestration_cell)

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print('Done.')
",Complexity:1,Description:
